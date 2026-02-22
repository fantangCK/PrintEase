# PrintEase 印易 - API 文档

## 一、概述

本文档详细介绍 PrintEase 后端 API 接口，包括认证、文件、订单、系统等模块。

**Base URL**: `http://localhost:3000/api`

**认证方式**: JWT Bearer Token

---

## 二、认证模块

### 2.1 微信登录

**接口**: `POST /auth/wechat-login`

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
  code: 200;
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
  code: 200;
  message: "success";
  data: {
    id: number;
    fileName: string;
    filePath: string;
    fileSize: number;
    fileType: string;
    fileExt: string;
    totalPages?: number;
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
    items: [
      {
        id: number;
        fileName: string;
        filePath: string;
        fileSize: number;
        fileExt: string;
        totalPages?: number;
        createdAt: string;
      }
    ],
    total: number;
    page: number;
    limit: number;
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
  fileIds: number[];         // 文件 ID 列表
  copies: number;             // 打印份数
  paperSize: string;          // 纸张大小（A4/A5/A3）
  colorType: number;          // 颜色类型（0=黑白，1=彩色）
  doubleSided: number;        // 双面打印（0=单面，1=双面）
  printQuality: string;       // 打印质量（draft/normal/high）
  remark?: string;            // 备注（可选）
  deliveryAddress?: string;   // 派送地址（可选）
  deliveryTime?: string;      // 派送时间（可选）
}
```

**响应**:
```typescript
{
  code: 200;
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
    deliveryAddress?: string;
    deliveryTime?: string;
    createdAt: string;
    files: [                  // 订单文件列表
      {
        id: number;
        fileName: string;
        filePath: string;
        convertedPdfPath?: string;
        pages: number;
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
    items: [
      {
        id: string;
        totalPages: number;
        copies: number;
        totalAmount: number;
        status: number;
        createdAt: string;
        files: [
          {
            id: number;
            fileName: string;
            convertedPdfPath?: string;
          }
        ]
      }
    ],
    total: number;
    page: number;
    limit: number;
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
    deliveryAddress?: string;
    deliveryTime?: string;
    printTime?: string;
    createdAt: string;
    updatedAt: string;
    files: [
      {
        id: number;
        fileName: string;
        filePath: string;
        convertedPdfPath?: string;
        pages: number;
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

**接口**: `POST /admin/login`

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
  code: 200;
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

**文档版本**：v1.0  
**创建日期**：2026-02-19
