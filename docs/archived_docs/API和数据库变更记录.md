# PrintEase API 和数据库变更记录

## 一、数据库变更

### 1.1 新增表：merchants（商户表）

```sql
CREATE TABLE `merchants` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '商户名称',
  `phone` varchar(20) NOT NULL COMMENT '手机号',
  `password` varchar(255) DEFAULT NULL COMMENT '密码（加密）',
  `address` varchar(255) DEFAULT NULL COMMENT '地址',
  `main_building_id` int DEFAULT NULL COMMENT '主要接单栋ID',
  `main_building_name` varchar(100) DEFAULT NULL COMMENT '主要接单栋名称',
  `status` tinyint DEFAULT '1' COMMENT '状态：1-启用，0-禁用',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商户表';
```

### 1.2 订单表新增字段

```sql
ALTER TABLE `orders` 
ADD COLUMN `merchant_id` int DEFAULT NULL COMMENT '商户ID' AFTER `mpay_pay_url`,
ADD INDEX `idx_merchant_id` (`merchant_id`);
```

---

## 二、后端 API 文档

### 2.1 商户管理 API

#### 2.1.1 创建商户

- **接口**: `POST /api/user/merchants`
- **认证**: 需要 Bearer Token
- **请求体**:
```json
{
  "name": "打印店-1栋",
  "phone": "13800138001",
  "password": "123456",
  "address": "1栋101室",
  "mainBuildingId": 1,
  "mainBuildingName": "1栋"
}
```
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "name": "打印店-1栋",
    "phone": "13800138001",
    "address": "1栋101室",
    "mainBuildingId": 1,
    "mainBuildingName": "1栋",
    "status": 1,
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

#### 2.1.2 获取商户列表

- **接口**: `GET /api/user/merchants`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": 1,
      "name": "打印店-1栋",
      "phone": "13800138001",
      "address": "1栋101室",
      "mainBuildingId": 1,
      "mainBuildingName": "1栋",
      "status": 1,
      "createdAt": "2024-01-20T10:30:00.000Z"
    }
  ]
}
```

#### 2.1.3 获取商户详情

- **接口**: `GET /api/user/merchants/:id`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "name": "打印店-1栋",
    "phone": "13800138001",
    "address": "1栋101室",
    "mainBuildingId": 1,
    "mainBuildingName": "1栋",
    "status": 1,
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

#### 2.1.4 更新商户

- **接口**: `PUT /api/user/merchants/:id`
- **认证**: 需要 Bearer Token
- **请求体**:
```json
{
  "name": "打印店-1栋",
  "phone": "13800138001",
  "password": "123456",
  "address": "1栋101室",
  "mainBuildingId": 1,
  "mainBuildingName": "1栋",
  "status": 1
}
```
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "name": "打印店-1栋",
    "phone": "13800138001",
    "address": "1栋101室",
    "mainBuildingId": 1,
    "mainBuildingName": "1栋",
    "status": 1
  }
}
```

#### 2.1.5 删除商户

- **接口**: `DELETE /api/user/merchants/:id`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

### 2.2 文件管理 API

#### 2.2.1 上传文件

- **接口**: `POST /api/files/upload`
- **认证**: 需要 Bearer Token
- **Content-Type**: `multipart/form-data`
- **参数**: `file` (文件)
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "fileName": "test.pdf",
    "fileSize": 102400,
    "fileType": "application/pdf",
    "fileExt": "pdf",
    "totalPages": 10,
    "conversionStatus": "pending",
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

#### 2.2.2 获取文件信息

- **接口**: `GET /api/files/:id`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "fileName": "test.pdf",
    "filePath": "http://localhost:3000/api/files/1/download",
    "fileSize": 102400,
    "fileType": "application/pdf",
    "fileExt": "pdf",
    "totalPages": 10,
    "conversionStatus": "completed",
    "convertedPdfPath": "http://localhost:3000/api/files/1/download-pdf",
    "blackWhiteCoverage": 80,
    "colorCoverage": 20,
    "conversionError": null,
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

#### 2.2.3 获取文件列表

- **接口**: `GET /api/files`
- **认证**: 需要 Bearer Token
- **查询参数**:
  - `page`: 页码（默认 1）
  - `limit`: 每页数量（默认 10）
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [
      {
        "id": 1,
        "fileName": "test.pdf",
        "fileSize": 102400,
        "fileType": "application/pdf",
        "fileExt": "pdf",
        "totalPages": 10,
        "conversionStatus": "completed",
        "createdAt": "2024-01-20T10:30:00.000Z"
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 10,
    "totalPages": 10
  }
}
```

#### 2.2.4 下载原文件

- **接口**: `GET /api/files/:id/download`
- **认证**: 不需要
- **响应**: 文件流

#### 2.2.5 下载转换后的 PDF

- **接口**: `GET /api/files/:id/download-pdf`
- **认证**: 不需要
- **响应**: PDF 文件流

#### 2.2.6 删除文件

- **接口**: `DELETE /api/files/:id`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

### 2.3 订单管理 API

#### 2.3.1 创建订单

- **接口**: `POST /api/orders`
- **认证**: 需要 Bearer Token
- **请求体**:
```json
{
  "fileIds": [1, 2],
  "copies": 1,
  "paperSize": "A4",
  "colorType": 0,
  "doubleSided": 0,
  "printQuality": "normal",
  "remark": "",
  "deliveryBuildingId": 1,
  "deliveryBuildingName": "1栋"
}
```
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "ORD20240120001",
    "totalPages": 10,
    "copies": 1,
    "paperSize": "A4",
    "colorType": 0,
    "doubleSided": 0,
    "printQuality": "normal",
    "totalAmount": 1.00,
    "status": 1,
    "remark": "",
    "createdAt": "2024-01-20T10:30:00.000Z",
    "files": [
      {
        "id": 1,
        "fileId": 1,
        "fileName": "test.pdf",
        "pages": 10
      }
    ]
  }
}
```

#### 2.3.2 获取订单详情

- **接口**: `GET /api/orders/:id`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "ORD20240120001",
    "totalPages": 10,
    "copies": 1,
    "paperSize": "A4",
    "colorType": 0,
    "doubleSided": 0,
    "printQuality": "normal",
    "totalAmount": 1.00,
    "status": 2,
    "remark": "",
    "mpayTradeNo": "MPAY20240120001",
    "mpayPayUrl": "http://...",
    "createdAt": "2024-01-20T10:30:00.000Z",
    "updatedAt": "2024-01-20T10:35:00.000Z",
    "files": [
      {
        "id": 1,
        "fileId": 1,
        "fileName": "test.pdf",
        "pages": 10
      }
    ]
  }
}
```

#### 2.3.3 获取订单列表

- **接口**: `GET /api/orders`
- **认证**: 需要 Bearer Token
- **查询参数**:
  - `page`: 页码（默认 1）
  - `limit`: 每页数量（默认 10）
  - `status`: 订单状态（可选）
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [
      {
        "id": "ORD20240120001",
        "totalPages": 10,
        "copies": 1,
        "paperSize": "A4",
        "colorType": 0,
        "doubleSided": 0,
        "printQuality": "normal",
        "totalAmount": 1.00,
        "status": 2,
        "remark": "",
        "mpayTradeNo": "MPAY20240120001",
        "mpayPayUrl": "http://...",
        "createdAt": "2024-01-20T10:30:00.000Z",
        "fileCount": 1
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 10,
    "totalPages": 10
  }
}
```

#### 2.3.4 取消订单

- **接口**: `PUT /api/orders/:id/cancel`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": null
}
```

#### 2.3.5 创建支付

- **接口**: `POST /api/orders/:id/pay`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "payUrl": "http://..."
  }
}
```

#### 2.3.6 刷新订单状态

- **接口**: `PUT /api/orders/:id/refresh`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "ORD20240120001",
    "status": 2,
    "totalAmount": 1.00,
    "files": [...]
  }
}
```

### 2.4 认证 API

#### 2.4.1 微信登录

- **接口**: `POST /api/auth/wechat-login`
- **请求体**:
```json
{
  "code": "wx_login_code"
}
```
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 1,
      "openid": "xxx",
      "nickname": "用户",
      "avatar": "http://..."
    }
  }
}
```

#### 2.4.2 获取当前用户信息

- **接口**: `GET /api/user/me`
- **认证**: 需要 Bearer Token
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "openid": "xxx",
    "nickname": "用户",
    "avatar": "http://...",
    "phone": "13800138000",
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

#### 2.4.3 更新当前用户信息

- **接口**: `PUT /api/user/me`
- **认证**: 需要 Bearer Token
- **请求体**:
```json
{
  "nickname": "新昵称",
  "avatar": "http://...",
  "phone": "13800138000"
}
```
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "nickname": "新昵称",
    "avatar": "http://...",
    "phone": "13800138000"
  }
}
```

### 2.5 系统配置 API

#### 2.5.1 获取系统配置

- **接口**: `GET /api/system/config`
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "notice": "欢迎使用印易打印",
    "servicePhone": "400-000-0000"
  }
}
```

#### 2.5.2 获取价格配置

- **接口**: `GET /api/system/price-config`
- **响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": 1,
      "paperSize": "A4",
      "colorType": 0,
      "doubleSided": 0,
      "pricePerPage": 0.10
    }
  ]
}
```

---

## 三、订单状态枚举

| 值 | 状态 | 说明 |
|----|------|------|
| 1 | 待支付 | 订单已创建，等待支付 |
| 2 | 待接单 | 支付成功，等待商户接单 |
| 3 | 打印中 | 商户已接单，正在打印 |
| 4 | 已完成 | 打印完成 |
| 5 | 已取消 | 订单已取消 |

---

## 四、打印参数枚举

### 4.1 颜色类型 (ColorType)

| 值 | 说明 |
|----|------|
| 0 | 黑白 |
| 1 | 彩色 |

### 4.2 单双面 (DoubleSided)

| 值 | 说明 |
|----|------|
| 0 | 单面 |
| 1 | 双面 |

### 4.3 打印质量 (PrintQuality)

| 值 | 说明 |
|----|------|
| normal | 普通 |
| high | 高清 |

---

## 五、文件转换状态

| 状态 | 说明 |
|------|------|
| pending | 待转换 |
| converting | 转换中 |
| completed | 转换完成 |
| failed | 转换失败 |

---

## 六、前端页面路由

| 路径 | 页面 | 说明 |
|------|------|------|
| /pages/admin/index | 管理后台首页 | 管理端主页面 |
| /pages/admin/login | 管理员登录 | 管理员登录页面 |
| /pages/admin/price-settings | 价格管理 | 价格配置页面 |
| /pages/admin/merchant-list | 商户管理 | 商户列表页面 |
| /pages/admin/merchant-create | 创建商户 | 创建新商户页面 |
| /pages/admin/order-list | 订单管理 | 订单管理页面 |
| /pages/merchant/index | 商户中心 | 商户端主页面 |
| /pages/merchant/login | 商户登录 | 商户登录页面 |
| /pages/merchant/settings | 商户设置 | 商户设置页面 |
| /pages/merchant/grab-orders | 抢单大厅 | 抢单大厅页面 |

---

## 七、数据库初始化脚本

项目已配置 TypeORM 自动同步，在开发环境下会自动创建和更新表结构。

如果需要手动初始化，可以使用以下步骤：

1. 确保数据库连接配置正确
2. 启动后端服务
3. TypeORM 会自动创建所有表结构

注意：在生产环境中，建议关闭 `synchronize`，使用迁移脚本。
