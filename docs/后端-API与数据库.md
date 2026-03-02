# PrintEase 印易 - 后端 API 与数据库完整文档

本文档集成了数据库设计、API 接口文档、商户 API 文档以及 API 和数据库的变更记录。

---

# 第一部分：数据库设计

## 一、数据库信息

- **数据库名**：`print_ease`
- **字符集**：`utf8mb4`
- **排序规则**：`utf8mb4_unicode_ci`
- **数据库引擎**：InnoDB

---

## 二、数据库初始化 SQL

```sql
CREATE DATABASE IF NOT EXISTS `print_ease` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `print_ease`;
```

---

## 三、枚举值定义

### 3.1 订单状态 (order_status)
| 值 | 说明 |
|----|------|
| 0 | 待支付 |
| 1 | 待打印 |
| 2 | 打印中 |
| 3 | 已完成 |
| 4 | 已取消 |
| 5 | 已失败 |

### 3.2 打印任务状态 (print_task_status)
| 值 | 说明 |
|----|------|
| 0 | 待分配 |
| 1 | 已分配 |
| 2 | 打印中 |
| 3 | 已完成 |
| 4 | 已失败 |

### 3.3 节点状态 (node_status)
| 值 | 说明 |
|----|------|
| 0 | 离线 |
| 1 | 在线 |

### 3.4 颜色类型 (color_type)
| 值 | 说明 |
|----|------|
| 0 | 黑白 |
| 1 | 彩色 |

### 3.5 双面打印 (double_sided)
| 值 | 说明 |
|----|------|
| 0 | 单面 |
| 1 | 长边翻转 |
| 2 | 短边翻转 |

### 3.6 管理员角色 (admin_role)
| 值 | 说明 |
|----|------|
| 0 | 超级管理员 |
| 1 | 普通管理员 |

---

## 四、数据表设计

### 4.1 用户表 (users)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | INT | PRIMARY KEY AUTO_INCREMENT | - | 用户ID |
| openid | VARCHAR(100) | UNIQUE NOT NULL | - | 微信OpenID |
| nickname | VARCHAR(50) | NULL | NULL | 昵称 |
| avatar | VARCHAR(255) | NULL | NULL | 头像URL |
| phone | VARCHAR(20) | NULL | NULL | 手机号 |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引**：
- `idx_openid` (openid)

---

### 4.2 文件表 (files)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | INT | PRIMARY KEY AUTO_INCREMENT | - | 文件ID |
| user_id | INT | NOT NULL | - | 上传用户ID |
| file_name | VARCHAR(255) | NOT NULL | - | 原始文件名 |
| file_path | VARCHAR(255) | NOT NULL | - | 文件存储路径 |
| file_size | BIGINT | NOT NULL | - | 文件大小（字节） |
| file_type | VARCHAR(50) | NOT NULL | - | 文件MIME类型 |
| file_ext | VARCHAR(20) | NOT NULL | - | 文件扩展名 |
| preview_path | VARCHAR(255) | NULL | NULL | 预览图路径 |
| total_pages | INT | NULL | NULL | 总页数（PDF/DOC等） |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| deleted_at | DATETIME | NULL | NULL | 删除时间（软删除） |

**索引**：
- `idx_user_id` (user_id)
- `idx_created_at` (created_at)

**外键**：
- `fk_files_user` (user_id) → users(id)

---

### 4.3 订单表 (orders)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | VARCHAR(32) | PRIMARY KEY | - | 订单号（如：PE202502190001） |
| user_id | INT | NOT NULL | - | 用户ID |
| total_pages | INT | NOT NULL | - | 总页数 |
| copies | INT | NOT NULL | 1 | 打印份数 |
| paper_size | VARCHAR(10) | NOT NULL | 'A4' | 纸张大小（A4/A5/A3） |
| color_type | TINYINT | NOT NULL | 0 | 颜色类型（0:黑白, 1:彩色） |
| double_sided | TINYINT | NOT NULL | 0 | 双面打印（0:单面, 1:长边, 2:短边） |
| page_range | VARCHAR(50) | NULL | NULL | 打印页码范围（如 "1-5, 8"） |
| print_quality | VARCHAR(20) | NOT NULL | 'normal' | 打印质量（draft/normal/high） |
| total_amount | DECIMAL(10,2) | NOT NULL | 0.00 | 总金额（元） |
| status | TINYINT | NOT NULL | 0 | 订单状态（见枚举） |
| print_time | DATETIME | NULL | NULL | 打印完成时间 |
| remark | VARCHAR(500) | NULL | NULL | 备注 |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引**：
- `idx_user_id` (user_id)
- `idx_status` (status)
- `idx_created_at` (created_at)

**外键**：
- `fk_orders_user` (user_id) → users(id)

---

### 4.4 订单文件关联表 (order_files)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | INT | PRIMARY KEY AUTO_INCREMENT | - | 关联ID |
| order_id | VARCHAR(32) | NOT NULL | - | 订单号 |
| file_id | INT | NOT NULL | - | 文件ID |
| pages | INT | NOT NULL | 1 | 该文件打印页数 |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |

**索引**：
- `idx_order_id` (order_id)
- `idx_file_id` (file_id)

**外键**：
- `fk_order_files_order` (order_id) → orders(id)
- `fk_order_files_file` (file_id) → files(id)

---

### 4.5 云印调度节点表 (dispatch_nodes)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | INT | PRIMARY KEY AUTO_INCREMENT | - | 节点ID |
| node_name | VARCHAR(100) | NOT NULL | - | 节点名称 |
| node_key | VARCHAR(100) | UNIQUE NOT NULL | - | 节点认证密钥 |
| status | TINYINT | NOT NULL | 0 | 节点状态（0:离线, 1:在线） |
| os_type | VARCHAR(20) | NULL | NULL | 操作系统类型（windows/linux/macos） |
| arch | VARCHAR(20) | NULL | NULL | 架构（x86_64/arm64等） |
| printers | JSON | NULL | NULL | 可用打印机列表 |
| ip_address | VARCHAR(50) | NULL | NULL | IP地址 |
| last_heartbeat | DATETIME | NULL | NULL | 最后心跳时间 |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引**：
- `idx_node_key` (node_key)
- `idx_status` (status)
- `idx_last_heartbeat` (last_heartbeat)

---

### 4.6 打印任务表 (print_tasks)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | VARCHAR(32) | PRIMARY KEY | - | 任务ID |
| order_id | VARCHAR(32) | NOT NULL | - | 订单号 |
| node_id | INT | NULL | NULL | 分配的节点ID |
| file_id | INT | NOT NULL | - | 文件ID |
| print_params | JSON | NOT NULL | - | 打印参数（完整JSON） |
| status | TINYINT | NOT NULL | 0 | 任务状态（见枚举） |
| error_msg | TEXT | NULL | NULL | 错误信息 |
| started_at | DATETIME | NULL | NULL | 开始打印时间 |
| completed_at | DATETIME | NULL | NULL | 完成时间 |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引**：
- `idx_order_id` (order_id)
- `idx_node_id` (node_id)
- `idx_status` (status)
- `idx_created_at` (created_at)

**外键**：
- `fk_print_tasks_order` (order_id) → orders(id)
- `fk_print_tasks_node` (node_id) → dispatch_nodes(id)
- `fk_print_tasks_file` (file_id) → files(id)

---

### 4.7 管理员表 (admins)

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|----------|------|--------|------|
| id | INT | PRIMARY KEY AUTO_INCREMENT | - | 管理员ID |
| username | VARCHAR(50) | UNIQUE NOT NULL | - | 用户名 |
| password | VARCHAR(255) | NOT NULL | - | 密码（bcrypt加密） |
| real_name | VARCHAR(50) | NULL | NULL | 真实姓名 |
| role | TINYINT | NOT NULL | 1 | 角色（0:超级管理员, 1:普通管理员） |
| last_login_at | DATETIME | NULL | NULL | 最后登录时间 |
| last_login_ip | VARCHAR(50) | NULL | NULL | 最后登录IP |
| created_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引**：
- `idx_username` (username)

---

## 五、Seed 数据（初始数据）

### 5.1 管理员账号

```sql
INSERT INTO admins (username, password, real_name, role) 
VALUES ('admin', '$2b$12$YourHashedPasswordHere', '超级管理员', 0);
```

---

## 六、数据库连接配置

### 6.1 环境变量 (.env)

```env
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=your_password
DB_DATABASE=print_ease
```

### 6.2 TypeORM 配置 (NestJS)

```typescript
// src/config/database.config.ts
export default () => ({
  database: {
    type: 'mysql',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    username: process.env.DB_USERNAME || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_DATABASE || 'print_ease',
    entities: [__dirname + '/../**/*.entity{.ts,.js}'],
    migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
    synchronize: process.env.NODE_ENV === 'development',
    logging: process.env.NODE_ENV === 'development',
  },
});
```

---

## 七、数据库迁移（TypeORM）

### 7.1 创建迁移

```bash
# 生成迁移文件
npm run migration:generate --name=InitTables

# 运行迁移
npm run migration:run

# 回滚迁移
npm run migration:revert
```

---

# 第二部分：API 文档

## 一、概述

本文档详细介绍 PrintEase 后端 API 接口，包括认证、文件、订单、系统等模块。

**Base URL**: `http://localhost:3000/api`

**认证方式**: JWT Bearer Token

---

## 二、认证模块

### 2.1 微信登录

**接口**: `POST /auth/wechat`

**描述**: 使用微信 code 登录或注册

**请求参数**:
```typescript
{
  code: string;  // 微信登录 code
}
```

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    accessToken: string;  // JWT Token
    user: {
      id: number;
      openid: string;
      nickname?: string;
      avatar?: string;
    }
  }
}
```

### 2.2 商户登录

**接口**: `POST /auth/merchant`

**描述**: 商户使用手机号和密码登录

**请求参数**:
```typescript
{
  phone: string;      // 手机号
  password: string;   // 密码
}
```

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    accessToken: string;  // JWT Token
    merchant: {
      id: number;
      name: string;
      phone: string;
      address?: string;
      apiKey: string;
      mainBuildingId?: number;
      mainBuildingName?: string;
    }
  }
}
```

---

## 三、文件模块

### 3.1 上传文件

**接口**: `POST /files/upload`

**描述**: 上传文件到服务器

**认证**: 需要

**请求**: `multipart/form-data`
- `file`: 文件

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    id: number;
    fileName: string;
    fileSize: number;
    fileType: string;
    fileExt: string;
    conversionStatus: string;
    createdAt: string;
  }
}
```

### 3.2 获取文件信息

**接口**: `GET /files/:id`

**描述**: 获取指定文件的详细信息

**认证**: 需要

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    id: number;
    userId: number;
    fileName: string;
    filePath: string;
    fileSize: number;
    fileType: string;
    fileExt: string;
    totalPages?: number;
    convertedPdfPath?: string;
    conversionStatus: string;
    blackWhiteCoverage?: number;
    colorCoverage?: number;
    conversionError?: string;
    convertedAt?: string;
    createdAt: string;
  }
}
```

### 3.3 下载文件

**接口**: `GET /files/:id/download`

**描述**: 下载文件

**认证**: 不需要（为了小程序下载方便）

**响应**: 文件流

### 3.4 获取文件列表

**接口**: `GET /files`

**描述**: 获取当前用户的文件列表

**认证**: 需要

**查询参数**:
- `page`: 页码（默认 1）
- `limit`: 每页数量（默认 20）

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    list: [
      {
        id: number;
        fileName: string;
        fileSize: number;
        fileType: string;
        fileExt: string;
        totalPages?: number;
        conversionStatus: string;
        createdAt: string;
      }
    ],
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }
}
```

---

## 四、订单模块

### 4.1 创建订单

**接口**: `POST /orders`

**描述**: 创建新订单

**认证**: 需要

**请求参数**:
```typescript
{
  files: Array<{ fileId: number; pages?: number }>; // 文件 ID 和页数列表
  copies: number;             // 打印份数
  paperSize: string;          // 纸张大小（A4/A5/A3）
  colorType: number;          // 颜色类型（0=黑白，1=彩色）
  doubleSided: number;        // 双面打印（0=单面，1=长边，2=短边）
  pageRange?: string;         // 打印页码范围（可选，如 "1-5, 8"）
  printQuality: string;       // 打印质量（draft/normal/high）
  remark?: string;            // 备注（可选）
  deliveryBuildingId: number; // 派送楼栋ID
  deliveryBuildingName: string; // 派送楼栋名称
  deliveryTimeSlotId: number; // 派送时间段ID
  deliveryTimeSlotName: string; // 派送时间段名称
  deliveryTime: string;       // 派送时间
}
```

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    id: string;               // 订单号
    userId: number;
    totalPages: number;
    copies: number;
    paperSize: string;
    colorType: number;
    doubleSided: number;
    printQuality: string;
    totalAmount: number;
    status: number;
    remark?: string;
    pageRange?: string;
    deliveryBuildingId: number;
    deliveryBuildingName: string;
    deliveryTimeSlotId: number;
    deliveryTimeSlotName: string;
    deliveryTime: string;
    createdAt: string;
    orderFiles: [             // 订单文件列表
      {
        id: number;
        fileId: number;
        pages: number;
        file: {
          id: number;
          fileName: string;
          fileExt: string;
          totalPages: number;
          convertedPdfPath: string;
        }
      }
    ]
  }
}
```

### 4.2 获取订单列表

**接口**: `GET /orders`

**描述**: 获取当前用户的订单列表

**认证**: 需要

**查询参数**:
- `page`: 页码（默认 1）
- `limit`: 每页数量（默认 20）
- `status?: number`: 订单状态筛选（可选）

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    list: [
      {
        id: string;
        totalPages: number;
        copies: number;
        paperSize: string;
        colorType: number;
        doubleSided: number;
        printQuality: string;
        totalAmount: number;
        status: number;
        remark?: string;
        mpayTradeNo?: string;
        mpayPayUrl?: string;
        createdAt: string;
        orderFiles: [
          {
            id: number;
            fileId: number;
            pages: number;
            file: {
              id: number;
              fileName: string;
              fileExt: string;
              totalPages: number;
              convertedPdfPath: string;
            }
          }
        ]
      }
    ],
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }
}
```

### 4.3 获取订单详情

**接口**: `GET /orders/:id`

**描述**: 获取指定订单的详细信息

**认证**: 需要

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    id: string;
    userId: number;
    totalPages: number;
    copies: number;
    paperSize: string;
    colorType: number;
    doubleSided: number;
    printQuality: string;
    totalAmount: number;
    status: number;
    remark?: string;
    pageRange?: string;
    deliveryBuildingId: number;
    deliveryBuildingName: string;
    deliveryTimeSlotId: number;
    deliveryTimeSlotName: string;
    deliveryTime: string;
    printTime?: string;
    mpayTradeNo?: string;
    mpayPayUrl?: string;
    mpayRealPrice?: number;
    mpayCreatedAt?: string;
    merchantId?: number;
    merchant?: {
      id: number;
      name: string;
      phone: string;
    };
    deliveryImageUrl?: string;
    createdAt: string;
    updatedAt: string;
    orderFiles: [
      {
        id: number;
        fileId: number;
        pages: number;
        file: {
          id: number;
          fileName: string;
          fileExt: string;
          totalPages: number;
          convertedPdfPath: string;
        }
      }
    ]
  }
}
```

### 4.4 取消订单

**接口**: `PUT /orders/:id/cancel`

**描述**: 取消订单

**认证**: 需要

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    id: string;
    status: number;  // 4 = 已取消
  }
}
```

### 4.5 创建支付

**接口**: `POST /orders/:id/pay`

**描述**: 为订单创建支付链接

**认证**: 需要

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    tradeNo: string;
    payUrl: string;
    realPrice?: number;
  }
}
```

### 4.6 刷新订单状态

**接口**: `PUT /orders/:id/refresh`

**描述**: 刷新订单状态，检查支付是否完成

**认证**: 需要

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    id: string;
    status: number;
    totalAmount: number;
    orderFiles: [
      {
        id: number;
        fileId: number;
        pages: number;
        file: {
          id: number;
          fileName: string;
          fileExt: string;
          totalPages: number;
          convertedPdfPath: string;
        }
      }
    ]
  }
}
```

---

## 五、系统模块

### 5.1 获取价格配置

**接口**: `GET /system/price-config`

**描述**: 获取当前激活的价格配置

**认证**: 不需要

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    id: number;
    blackWhiteSingleSidedPrice: number;
    blackWhiteDoubleSidedPrice: number;
    colorSingleSidedPrice: number;
    colorDoubleSidedPrice: number;
    minPrice: number;
    isActive: boolean;
  }
}
```

### 5.2 获取公告配置

**接口**: `GET /system/notice-config`

**描述**: 获取公告配置

**认证**: 不需要

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    title: string;
    content: string;
    wechatNumber: string;
    wechatImageUrl: string;
    isActive: boolean;
  }
}
```

### 5.3 管理员：更新价格配置

**接口**: `PUT /admin/price-config`

**描述**: 更新价格配置（管理员接口）

**认证**: 需要（管理员）

**请求参数**:
```typescript
{
  blackWhiteSingleSidedPrice?: number;
  blackWhiteDoubleSidedPrice?: number;
  colorSingleSidedPrice?: number;
  colorDoubleSidedPrice?: number;
  minPrice?: number;
}
```

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    id: number;
    blackWhiteSingleSidedPrice: number;
    blackWhiteDoubleSidedPrice: number;
    colorSingleSidedPrice: number;
    colorDoubleSidedPrice: number;
    minPrice: number;
    isActive: boolean;
  }
}
```

### 5.4 管理员：更新公告配置

**接口**: `PUT /admin/notice-config`

**描述**: 更新公告配置（管理员接口）

**认证**: 需要（管理员）

**请求参数**:
```typescript
{
  title?: string;
  content?: string;
  wechatNumber?: string;
  isActive?: boolean;
}
```

**响应**:
```typescript
{
  code: 200;
  message: "success";
  data: {
    title: string;
    content: string;
    wechatNumber: string;
    wechatImageUrl: string;
    isActive: boolean;
  }
}
```

---

## 六、管理员模块

### 6.1 管理员登录

**接口**: `POST /auth/admin`

**描述**: 管理员登录

**请求参数**:
```typescript
{
  username: string;
  password: string;
}
```

**响应**:
```typescript
{
  code: 0;
  message: "success";
  data: {
    accessToken: string;
    admin: {
      id: number;
      username: string;
      realName?: string;
      role: number;
    }
  }
}
```

### 6.2 获取所有订单（管理员）

**接口**: `GET /admin/orders`

**描述**: 获取所有订单（管理员接口）

**认证**: 需要（管理员）

**查询参数**:
- `page`: 页码（默认 1）
- `limit`: 每页数量（默认 20）
- `status?: number`: 订单状态筛选（可选）

**响应**: 同 4.2 获取订单列表

---

## 七、错误响应格式

所有错误响应统一格式：

```typescript
{
  code: number;        // 错误码
  message: string;     // 错误信息
  data?: any;          // 可选数据
}
```

**常见错误码**:
- `400`: 请求参数错误
- `401`: 未认证
- `403`: 无权限
- `404`: 资源不存在
- `500`: 服务器内部错误

---

## 八、文件下载 URL 格式

为了小程序能正常下载文件，下载 URL 格式为：

```
http://localhost:3000/api/files/{id}/download
```

**注意**:
- URL 必须包含 `/api` 前缀
- 协议必须是 `http` 或 `https`
- 下载接口不需要认证

---

## 九、关键代码位置

### 9.1 后端控制器
- 认证控制器：`printease-backend/src/modules/auth/auth.controller.ts`
- 文件控制器：`printease-backend/src/modules/file/file.controller.ts`
- 订单控制器：`printease-backend/src/modules/order/order.controller.ts`
- 系统控制器：`printease-backend/src/modules/system/system.controller.ts`

### 9.2 前端 API 封装
- API 文件：`printease-uniapp/src/api/`
  - `auth.ts` - 认证相关
  - `file.ts` - 文件相关
  - `order.ts` - 订单相关
  - `system.ts` - 系统相关

---

# 第三部分：商户 API 文档

## 一、概述

本文档介绍 PrintEase 商户如何使用 API Key 接收和管理打印任务。

---

## 二、商户 API Key

### 2.1 获取 API Key

每个商户都有一个唯一的 API Key，用于身份认证。

**获取方式**:
1. 登录管理员后台
2. 进入商户管理页面
3. 查看商户详情即可看到 API Key

### 2.2 重新生成 API Key

如果 API Key 泄露，可以重新生成：

**接口**: `POST /api/user/merchants/:id/regenerate-api-key`

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "apiKey": "新的API Key"
  }
}
```

---

## 三、认证方式

商户 API 使用 HTTP Header 进行认证：

```
x-api-key: {你的API Key}
```

**示例**:
```bash
curl -H "x-api-key: abc123def456..." \
  http://localhost:3000/api/merchant/tasks
```

---

## 四、商户 API

### 4.1 获取商户信息

**接口**: `GET /merchant/tasks/profile`

**描述**: 获取商户信息

**请求 Header**:
```
x-api-key: {你的API Key}
```

**响应**:
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
    "apiKey": "your-api-key",
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

---

### 4.2 更新商户信息

**接口**: `PUT /merchant/tasks/profile`

**描述**: 更新商户信息

**请求 Header**:
```
x-api-key: {你的API Key}
```

**请求参数**:
```json
{
  "address": "1栋101室",
  "mainBuildingId": 1,
  "mainBuildingName": "1栋"
}
```

**响应**:
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
    "apiKey": "your-api-key",
    "createdAt": "2024-01-20T10:30:00.000Z"
  }
}
```

---

### 4.3 获取商户统计信息

**接口**: `GET /merchant/tasks/stats`

**描述**: 获取商户统计信息

**请求 Header**:
```
x-api-key: {你的API Key}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "pending": 5,
    "processing": 2,
    "todayCompleted": 10
  }
}
```

---

### 4.4 获取待接单的订单列表

**接口**: `GET /merchant/tasks/unassigned`

**描述**: 获取待接单的订单列表

**请求 Header**:
```
x-api-key: {你的API Key}
```

**查询参数**:
- `page`: 页码（默认 1）
- `limit`: 每页数量（默认 50）
- `buildingId`: 楼栋ID（可选）

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [
      {
        "id": "pay12345678901234567890123456",
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
        "orderFiles": [
          {
            "id": 1,
            "fileId": 1,
            "pages": 10,
            "file": {
              "id": 1,
              "fileName": "test.pdf",
              "fileExt": "pdf",
              "totalPages": 10,
              "convertedPdfPath": "uploads/converted/test.pdf"
            }
          }
        ]
      }
    ],
    "total": 10,
    "page": 1,
    "limit": 50
  }
}
```

---

### 4.5 商户接单

**接口**: `POST /merchant/tasks/:id/grab`

**描述**: 商户接取指定的待处理订单

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 订单 ID

**响应**:
```json
{
  "code": 0,
  "message": "接单成功"
}
```

---

### 4.6 取消接单（释放订单）

**接口**: `POST /merchant/tasks/:id/cancel`

**描述**: 商户取消已接的订单，释放回待接单池

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 订单 ID

**响应**:
```json
{
  "code": 0,
  "message": "取消接单成功，订单已释放"
}
```

---

### 4.7 获取商户的打印任务列表

**接口**: `GET /merchant/tasks`

**描述**: 获取商户的打印任务列表

**请求 Header**:
```
x-api-key: {你的API Key}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "task12345678901234567890123456",
      "orderId": "pay12345678901234567890123456",
      "merchantId": 1,
      "fileId": 1,
      "printParams": {
        "copies": 1,
        "colorType": 0,
        "doubleSided": 0,
        "paperSize": "A4",
        "printQuality": "normal",
        "pageRange": "1-5",
        "remark": ""
      },
      "status": 2,
      "errorMsg": null,
      "startedAt": "2024-01-20T10:35:00.000Z",
      "completedAt": null,
      "createdAt": "2024-01-20T10:30:00.000Z",
      "updatedAt": "2024-01-20T10:35:00.000Z",
      "order": {
        "id": "pay12345678901234567890123456",
        "totalPages": 10,
        "totalAmount": 1.00,
        "status": 2
      },
      "file": {
        "id": 1,
        "fileName": "test.pdf",
        "fileExt": "pdf",
        "totalPages": 10,
        "convertedPdfPath": "uploads/converted/test.pdf"
      }
    }
  ]
}
```

---

### 4.8 获取待处理的打印任务

**接口**: `GET /merchant/tasks/pending`

**描述**: 获取待处理的打印任务

**请求 Header**:
```
x-api-key: {你的API Key}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "task12345678901234567890123456",
      "orderId": "pay12345678901234567890123456",
      "merchantId": 1,
      "fileId": 1,
      "printParams": {
        "copies": 1,
        "colorType": 0,
        "doubleSided": 0,
        "paperSize": "A4",
        "printQuality": "normal"
      },
      "status": 2,
      "createdAt": "2024-01-20T10:30:00.000Z",
      "order": { ... },
      "file": { ... }
    }
  ]
}
```

---

### 4.9 获取打印任务详情

**接口**: `GET /merchant/tasks/:id`

**描述**: 获取打印任务详情

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 打印任务 ID

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task12345678901234567890123456",
    "orderId": "pay12345678901234567890123456",
    "merchantId": 1,
    "fileId": 1,
    "printParams": {
      "copies": 1,
      "colorType": 0,
      "doubleSided": 0,
      "paperSize": "A4",
      "printQuality": "normal",
      "pageRange": "1-5",
      "remark": ""
    },
    "status": 2,
    "errorMsg": null,
    "startedAt": "2024-01-20T10:35:00.000Z",
    "completedAt": null,
    "createdAt": "2024-01-20T10:30:00.000Z",
    "updatedAt": "2024-01-20T10:35:00.000Z",
    "order": {
      "id": "pay12345678901234567890123456",
      "userId": 1,
      "totalPages": 10,
      "copies": 1,
      "totalAmount": 1.00,
      "status": 2,
      "remark": "",
      "createdAt": "2024-01-20T10:30:00.000Z"
    },
    "file": {
      "id": 1,
      "fileName": "test.pdf",
      "fileExt": "pdf",
      "totalPages": 10,
      "convertedPdfPath": "uploads/converted/test.pdf"
    }
  }
}
```

---

### 4.10 开始打印任务

**接口**: `PUT /merchant/tasks/:id/start`

**描述**: 开始打印任务

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 打印任务 ID

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task12345678901234567890123456",
    "status": 2,
    "startedAt": "2024-01-20T10:35:00.000Z"
  }
}
```

---

### 4.11 完成打印任务

**接口**: `PUT /merchant/tasks/:id/complete`

**描述**: 完成打印任务

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 打印任务 ID

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task12345678901234567890123456",
    "status": 3,
    "completedAt": "2024-01-20T10:40:00.000Z"
  }
}
```

---

### 4.12 强制完成打印任务并同步订单

**接口**: `POST /merchant/tasks/:id/force-complete`

**描述**: 强制完成打印任务并同步订单状态

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 打印任务 ID

**响应**:
```json
{
  "code": 0,
  "message": "强制完成成功"
}
```

---

### 4.13 标记打印任务失败

**接口**: `PUT /merchant/tasks/:id/fail`

**描述**: 标记打印任务失败

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `id`: 打印任务 ID

**请求参数**:
```json
{
  "errorMsg": "打印失败原因"
}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "task12345678901234567890123456",
    "status": 4,
    "errorMsg": "打印失败原因"
  }
}
```

---

### 4.14 上传派送完成图片

**接口**: `POST /merchant/tasks/:orderId/upload-delivery-image`

**描述**: 上传派送完成图片文件

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `orderId`: 订单 ID

**请求**: `multipart/form-data`
- `file`: 图片文件

**响应**:
```json
{
  "code": 0,
  "message": "图片上传成功，订单已完成",
  "data": {
    "imageUrl": "http://localhost:3000/api/uploads/delivery/delivery_1234567890_abc123.jpg"
  }
}
```

---

### 4.15 完成订单

**接口**: `POST /merchant/tasks/:orderId/complete`

**描述**: 完成订单

**请求 Header**:
```
x-api-key: {你的API Key}
```

**路径参数**:
- `orderId`: 订单 ID

**响应**:
```json
{
  "code": 0,
  "message": "订单完成成功"
}
```

---

## 五、打印任务状态

| 值 | 说明 |
|----|------|
| 0 | 待分配 |
| 1 | 已分配 |
| 2 | 打印中 |
| 3 | 已完成 |
| 4 | 已失败 |

---

## 六、订单状态

| 值 | 说明 |
|----|------|
| 0 | 待支付 |
| 1 | 待打印 |
| 2 | 打印中 |
| 3 | 已打印 |
| 4 | 已完成 |
| 5 | 已取消 |
| 6 | 已失败 |

---

## 七、下载打印文件

打印任务关联的文件可以通过文件下载接口获取：

**接口**: `GET /api/files/:id/download`

**说明**:
- 不需要认证
- 需要使用转换后的 PDF 文件进行打印

**示例**:
```bash
# 先获取任务详情，得到 fileId
# 然后下载文件
curl -O http://localhost:3000/api/files/1/download
```

---

## 八、完整工作流程示例

### 8.1 商户接收打印任务流程

```
1. 商户客户端定期轮询待处理任务
   GET /api/merchant/tasks/pending
   ↓
2. 获取到新任务，查看任务详情
   GET /api/merchant/tasks/{taskId}
   ↓
3. 下载打印文件
   GET /api/files/{fileId}/download
   ↓
4. 开始打印，更新任务状态
   PUT /api/merchant/tasks/{taskId}/start
   ↓
5. 打印完成，更新任务状态
   PUT /api/merchant/tasks/{taskId}/complete
```

### 8.2 代码示例（Python）

```python
import requests
import time

API_BASE = "http://localhost:3000/api"
API_KEY = "你的API Key"
HEADERS = {"x-api-key": API_KEY}

def get_pending_tasks():
    """获取待处理任务"""
    url = f"{API_BASE}/merchant/tasks/pending"
    response = requests.get(url, headers=HEADERS)
    return response.json()["data"]

def start_task(task_id):
    """开始任务"""
    url = f"{API_BASE}/merchant/tasks/{task_id}/start"
    response = requests.put(url, headers=HEADERS)
    return response.json()

def complete_task(task_id):
    """完成任务"""
    url = f"{API_BASE}/merchant/tasks/{task_id}/complete"
    response = requests.put(url, headers=HEADERS)
    return response.json()

def download_file(file_id, save_path):
    """下载文件"""
    url = f"{API_BASE}/files/{file_id}/download"
    response = requests.get(url)
    with open(save_path, "wb") as f:
        f.write(response.content)

def main():
    while True:
        print("检查待处理任务...")
        tasks = get_pending_tasks()
        
        for task in tasks:
            print(f"处理任务: {task['id']}")
            
            # 开始任务
            start_task(task["id"])
            
            # 下载文件
            file_id = task["fileId"]
            download_file(file_id, f"task_{task['id']}.pdf")
            
            # 这里执行实际打印...
            print("打印中...")
            time.sleep(5)
            
            # 完成任务
            complete_task(task["id"])
            print(f"任务 {task['id']} 完成")
        
        time.sleep(10)  # 每10秒检查一次

if __name__ == "__main__":
    main()
```

---

## 九、错误码

| HTTP 状态码 | 说明 |
|------------|------|
| 401 | 无效的 API Key |
| 404 | 任务不存在 |
| 500 | 服务器内部错误 |

---

## 十、关键代码位置

- **商户实体**：`printease-backend/src/modules/user/entities/merchant.entity.ts`
- **商户服务**：`printease-backend/src/modules/user/user.service.ts`
- **商户打印任务控制器**：`printease-backend/src/modules/dispatch/dispatch.controller.ts`
- **打印任务实体**：`printease-backend/src/modules/dispatch/entities/print-task.entity.ts`

---

# 第四部分：API 和数据库变更记录

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

## 二、后端 API 变更

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
| /pages/merchant/grab-orders | 接单大厅 | 接单大厅页面 |

---

## 七、数据库初始化脚本

项目已配置 TypeORM 自动同步，在开发环境下会自动创建和更新表结构。

如果需要手动初始化，可以使用以下步骤：

1. 确保数据库连接配置正确
2. 启动后端服务
3. TypeORM 会自动创建所有表结构

注意：在生产环境中，建议关闭 `synchronize`，使用迁移脚本。
