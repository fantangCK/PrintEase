# 支付订单复用 - API 逻辑

## 概述

本文档描述了 PrintEase 印易项目中支付订单复用的后端 API 逻辑实现。

## 问题背景

原问题：每次用户点击支付按钮时，都会向 mpay 系统创建新的支付订单，导致订单重复创建。

解决方案：实现支付订单复用机制，在支付信息有效期（可配置，默认3分钟）内直接复用，超过有效期或不存在时才重新创建。

## 数据库表结构变更

### orders 表新增字段

在 `orders` 表中新增了 `mpay_created_at` 字段：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| mpay_created_at | datetime | 支付信息创建时间，用于判断支付订单是否过期 |

### 完整字段说明

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | varchar(32) | 订单ID（主键） |
| user_id | int | 用户ID |
| total_pages | int | 总页数 |
| copies | int | 份数 |
| paper_size | varchar(10) | 纸张大小 |
| color_type | tinyint | 颜色类型（0:黑白, 1:彩色） |
| double_sided | tinyint | 双面打印（0:单面, 1:双面） |
| print_quality | varchar(20) | 打印质量 |
| total_amount | decimal(10,2) | 订单总金额 |
| status | tinyint | 订单状态 |
| mpay_trade_no | varchar(100) | mpay 交易号 |
| mpay_pay_url | varchar(500) | mpay 支付链接 |
| mpay_created_at | datetime | 支付信息创建时间 |
| created_at | datetime | 订单创建时间 |
| updated_at | datetime | 订单更新时间 |

## 核心 API 接口

### 1. 创建支付接口

**接口地址**：`POST /api/orders/:id/payment`

**请求参数**：
- `id`: 订单ID（路径参数）

**返回参数**：
```json
{
  "tradeNo": "H20260220000001",
  "payUrl": "http://domain.com/Pay/console/H20260220000001"
}
```

### 2. 支付回调接口

**接口地址**：`GET /api/orders/pay/callback`

**请求参数**：mpay 系统推送的回调参数

## 核心实现逻辑

### createPayment 方法流程

`order.service.ts` 中的 `createPayment` 方法实现如下：

```
开始
  ↓
验证订单状态（必须是待支付）
  ↓
检查是否有支付信息（mpayTradeNo、mpayPayUrl、mpayCreatedAt）
  ↓
有支付信息？
  ├─ 是 → 检查是否过期（30分钟）
  │         ├─ 未过期 → 直接复用现有支付信息，返回
  │         └─ 已过期 → 取消订单，提示用户重新创建
  └─ 否 → 创建新的支付信息
              ↓
         调用 mpay API 创建订单
              ↓
         保存支付信息（mpayTradeNo、mpayPayUrl、mpayCreatedAt）
              ↓
         返回支付信息
```

### 详细步骤说明

1. **验证订单状态**
   - 只有状态为 `PENDING_PAYMENT`（待支付）的订单才能发起支付
   - 如果订单状态不对，抛出 `BadRequestException`

2. **检查支付信息是否存在且未过期**
   - 检查三个字段：`mpayTradeNo`、`mpayPayUrl`、`mpayCreatedAt`
   - 如果都存在，计算支付信息的年龄：`Date.now() - new Date(mpayCreatedAt).getTime()`
   - 有效期：从配置文件 `PAYMENT_EXPIRE_MINUTES` 读取，默认3分钟

3. **复用逻辑**
   - 如果支付信息年龄 < 配置的过期时间：直接返回现有的 `tradeNo` 和 `payUrl`
   - 记录日志：`✅ 复用已有支付信息`

4. **取消过期订单**
   - 如果支付信息已过期：
     - 将订单状态设置为 `CANCELLED`（已取消）
     - 清除三个字段：
       - `mpayTradeNo = null`
       - `mpayPayUrl = null`
       - `mpayCreatedAt = null`
   - 保存到数据库
   - 抛出异常提示用户："订单已过期，请重新创建订单"

5. **创建新支付信息**
   - 使用稳定的 `out_trade_no = order.id`（不带时间戳）
   - 调用 mpay `/mapi.php` 接口创建订单
   - 保存返回的 `trade_no` 和 `payurl`
   - 记录 `mpayCreatedAt = new Date()`

### 支付回调处理

`handlePayCallback` 方法：

1. **验证签名**：使用 mpay 密钥验证回调签名
2. **提取订单ID**：直接使用 `out_trade_no` 作为订单ID（因为现在 out_trade_no = 订单ID）
3. **验证金额**：确保回调金额与订单金额一致
4. **更新订单状态**：如果订单当前是待支付，更新为待打印

## 关键代码片段

### 1. Order 实体新增字段

```typescript
@Column({ name: 'mpay_created_at', type: 'datetime', nullable: true })
mpayCreatedAt: Date | null;
```

### 2. createPayment 方法核心逻辑

```typescript
async createPayment(id: string, userId: number): Promise<{ tradeNo: string; payUrl: string }> {
  const order = await this.findById(id, userId);
  
  if (order.status !== OrderStatus.PENDING_PAYMENT) {
    throw new BadRequestException('只有待支付的订单才能发起支付');
  }

  const expiredTime = 30 * 60 * 1000; // 30分钟
  
  // 检查是否已有支付信息且未过期
  if (order.mpayTradeNo && order.mpayPayUrl && order.mpayCreatedAt) {
    const paymentAge = Date.now() - new Date(order.mpayCreatedAt).getTime();
    
    if (paymentAge < expiredTime) {
      // 复用
      return {
        tradeNo: order.mpayTradeNo,
        payUrl: order.mpayPayUrl,
      };
    }
  }

  // 取消过期订单
  if (order.mpayTradeNo || order.mpayPayUrl || order.mpayCreatedAt) {
    order.status = OrderStatus.CANCELLED;
    order.mpayTradeNo = null;
    order.mpayPayUrl = null;
    order.mpayCreatedAt = null;
    await this.orderRepository.save(order);
    
    throw new BadRequestException('订单已过期，请重新创建订单');
  }

  // 创建新支付信息
  const outTradeNo = order.id; // 稳定的订单ID
  
  // 调用 mpay API...
  
  order.mpayTradeNo = response.data.trade_no;
  order.mpayPayUrl = response.data.payurl;
  order.mpayCreatedAt = new Date();
  await this.orderRepository.save(order);
  
  return {
    tradeNo: response.data.trade_no,
    payUrl: response.data.payurl,
  };
}
```

### 3. 支付回调处理

```typescript
async handlePayCallback(query: any) {
  const { out_trade_no, trade_status, sign, money } = query;
  
  // 验证签名...
  
  // 直接使用 out_trade_no 作为订单ID（不再需要 split）
  const originalOrderId = out_trade_no;
  const order = await this.orderRepository.findOne({ where: { id: originalOrderId } });
  
  // 验证金额...
  
  if (order.status === OrderStatus.PENDING_PAYMENT) {
    order.status = OrderStatus.PENDING_PRINT;
    await this.orderRepository.save(order);
  }
  
  return { success: true };
}
```

## 日志输出

所有关键步骤都有详细的日志输出，便于调试：

```
========== 开始创建支付 ==========
订单ID: pay12345678901234
订单状态: 0
现有mpayTradeNo: H20260220000001
现有mpayPayUrl: http://...
现有mpayCreatedAt: 2026-02-20T10:00:00.000Z
支付信息年龄: 120000ms, 过期时间: 1800000ms
✅ 复用已有支付信息: pay12345678901234, H20260220000001
========== 支付复用完成 ==========
```

## 配置说明

### 环境变量

在 `.env` 文件中添加以下配置：

```env
# 支付过期时间（分钟）
PAYMENT_EXPIRE_MINUTES=3
```

### 配置说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| PAYMENT_EXPIRE_MINUTES | 支付订单有效期（分钟） | 3 |

### 代码读取配置

在 `app.config.ts` 中添加了配置项：

```typescript
payment: {
  expireMinutes: parseInt(process.env.PAYMENT_EXPIRE_MINUTES || '3', 10),
}
```

在 `order.service.ts` 中读取配置：

```typescript
const expireMinutes = this.configService.get<number>('payment.expireMinutes') || 3;
const expiredTime = expireMinutes * 60 * 1000;
```

## 数据库同步

项目使用 TypeORM，在开发环境下开启了 `synchronize: true`，所以重启后端服务后会自动在数据库中添加 `mpay_created_at` 字段。

生产环境建议使用迁移文件。

## 注意事项

1. **out_trade_no 稳定性**：必须使用稳定的订单ID作为 `out_trade_no`，不能带时间戳后缀
2. **有效期设置**：支付信息有效期为30分钟，可根据业务需求调整
3. **幂等性**：支付回调处理需要做幂等性判断，防止重复处理
4. **日志记录**：所有关键操作都有日志记录，便于问题排查
