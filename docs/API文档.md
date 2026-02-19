# PrintEase 印易 - API 接口文档

**Base URL**: `http://localhost:3000/api`  
**API 版本**: v1  
**日期**: 2026-02-19

---

## 一、通用说明

### 1.1 响应格式

所有 API 响应统一格式：

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | 状态码（0:成功, 非0:失败） |
| message | string | 消息 |
| data | any | 数据 |

### 1.2 状态码说明

| code | 说明 |
|------|------|
| 0 | 成功 |
| 10001 | 参数错误 |
| 10002 | 未授权 |
| 10003 | 资源不存在 |
| 10004 | 业务错误 |
| 20001 | 系统错误 |

### 1.3 认证方式

**小程序端**：Header 中携带 `Authorization: Bearer {token}`  
**云印调度**：Header 中携带 `X-Node-Key: {node_key}`  
**管理后台**：Header 中携带 `Authorization: Bearer {admin_token}`

---

## 二、枚举值定义

### 2.1 订单状态 (order_status)
| 值 | 说明 |
|----|------|
| 0 | 待支付 |
| 1 | 待打印 |
| 2 | 打印中 |
| 3 | 已完成 |
| 4 | 已取消 |
| 5 | 已失败 |

### 2.2 打印任务状态 (print_task_status)
| 值 | 说明 |
|----|------|
| 0 | 待分配 |
| 1 | 已分配 |
| 2 | 打印中 |
| 3 | 已完成 |
| 4 | 已失败 |

### 2.3 节点状态 (node_status)
| 值 | 说明 |
|----|------|
| 0 | 离线 |
| 1 | 在线 |

### 2.4 颜色类型 (color_type)
| 值 | 说明 |
|----|------|
| 0 | 黑白 |
| 1 | 彩色 |

### 2.5 双面打印 (double_sided)
| 值 | 说明 |
|----|------|
| 0 | 单面 |
| 1 | 双面 |

### 2.6 打印质量 (print_quality)
| 值 | 说明 |
|----|------|
| draft | 草稿 |
| normal | 正常 |
| high | 高质量 |

---

## 三、认证模块 (Auth)

### 3.1 微信小程序登录

**接口**: `POST /auth/wechat`

**请求参数**:
```json
{
  "code": "wx_login_code"
}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "openid": "o1234567890",
      "nickname": "用户昵称",
      "avatar": "https://example.com/avatar.jpg"
    }
  }
}
```

---

### 3.2 刷新 Token

**接口**: `POST /auth/refresh`

**请求头**:
```
Authorization: Bearer {token}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## 四、用户模块 (User)

### 4.1 获取当前用户信息

**接口**: `GET /user/me`

**请求头**:
```
Authorization: Bearer {token}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "openid": "o1234567890",
    "nickname": "用户昵称",
    "avatar": "https://example.com/avatar.jpg",
    "phone": "13800138000",
    "created_at": "2026-02-19T10:00:00.000Z"
  }
}
```

---

### 4.2 更新用户信息

**接口**: `PUT /user/me`

**请求头**:
```
Authorization: Bearer {token}
```

**请求参数**:
```json
{
  "nickname": "新昵称",
  "avatar": "https://example.com/new-avatar.jpg",
  "phone": "13900139000"
}
```

---

## 五、文件模块 (File)

### 5.1 上传文件

**接口**: `POST /files/upload`

**请求头**:
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**请求参数** (FormData):
| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| file | File | 是 | 文件 |

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": 1,
    "file_name": "test.pdf",
    "file_size": 1024000,
    "file_type": "application/pdf",
    "file_ext": "pdf",
    "total_pages": 5,
    "created_at": "2026-02-19T10:00:00.000Z"
  }
}
```

---

### 5.2 获取文件信息

**接口**: `GET /files/:id`

**请求头**:
```
Authorization: Bearer {token}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 文件ID |

---

### 5.3 下载文件

**接口**: `GET /files/:id/download`

**请求头**:
```
Authorization: Bearer {token}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 文件ID |

---

### 5.4 删除文件

**接口**: `DELETE /files/:id`

**请求头**:
```
Authorization: Bearer {token}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | int | 文件ID |

---

## 六、订单模块 (Order)

### 6.1 创建订单

**接口**: `POST /orders`

**请求头**:
```
Authorization: Bearer {token}
```

**请求参数**:
```json
{
  "file_ids": [1, 2],
  "copies": 1,
  "paper_size": "A4",
  "color_type": 0,
  "double_sided": 0,
  "print_quality": "normal",
  "remark": "备注信息"
}
```

| 参数 | 类型 | 必需 | 说明 | 枚举值 |
|------|------|------|------|--------|
| file_ids | array | 是 | 文件ID列表 | - |
| copies | int | 否 | 打印份数，默认1 | - |
| paper_size | string | 否 | 纸张大小，默认A4 | A4/A5/A3 |
| color_type | int | 否 | 颜色类型，默认0 | 0:黑白, 1:彩色 |
| double_sided | int | 否 | 双面打印，默认0 | 0:单面, 1:双面 |
| print_quality | string | 否 | 打印质量，默认normal | draft/normal/high |
| remark | string | 否 | 备注 | - |

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "PE202602190001",
    "user_id": 1,
    "total_pages": 10,
    "copies": 1,
    "paper_size": "A4",
    "color_type": 0,
    "double_sided": 0,
    "print_quality": "normal",
    "total_amount": 5.00,
    "status": 0,
    "remark": "备注信息",
    "created_at": "2026-02-19T10:00:00.000Z",
    "files": [
      {
        "id": 1,
        "file_name": "test.pdf",
        "pages": 5
      }
    ]
  }
}
```

---

### 6.2 获取订单列表

**接口**: `GET /orders`

**请求头**:
```
Authorization: Bearer {token}
```

**查询参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认1 |
| limit | int | 否 | 每页数量，默认10 |
| status | int | 否 | 订单状态过滤 |

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "list": [
      {
        "id": "PE202602190001",
        "total_pages": 10,
        "total_amount": 5.00,
        "status": 1,
        "created_at": "2026-02-19T10:00:00.000Z"
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 10
  }
}
```

---

### 6.3 获取订单详情

**接口**: `GET /orders/:id`

**请求头**:
```
Authorization: Bearer {token}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 订单号 |

---

### 6.4 取消订单

**接口**: `PUT /orders/:id/cancel`

**请求头**:
```
Authorization: Bearer {token}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 订单号 |

**说明**: 仅可取消状态为 0(待支付) 或 1(待打印) 的订单

---

## 七、云印调度模块 (Dispatch)

### 7.1 节点注册

**接口**: `POST /dispatch/node/register`

**请求参数**:
```json
{
  "node_name": "打印节点-01",
  "os_type": "windows",
  "arch": "x86_64",
  "printers": [
    {
      "name": "HP LaserJet",
      "status": "ready"
    }
  ]
}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "node_id": 1,
    "node_key": "sk_abc123xyz789"
  }
}
```

---

### 7.2 节点心跳

**接口**: `POST /dispatch/node/heartbeat`

**请求头**:
```
X-Node-Key: {node_key}
```

**请求参数**:
```json
{
  "printers": [
    {
      "name": "HP LaserJet",
      "status": "ready"
    }
  ]
}
```

---

### 7.3 轮询任务

**接口**: `GET /dispatch/task/poll`

**请求头**:
```
X-Node-Key: {node_key}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "PT202602190001",
      "order_id": "PE202602190001",
      "file_id": 1,
      "print_params": {
        "copies": 1,
        "paper_size": "A4",
        "color_type": 0,
        "double_sided": 0,
        "print_quality": "normal"
      },
      "status": 0
    }
  ]
}
```

---

### 7.4 认领任务

**接口**: `POST /dispatch/task/:id/claim`

**请求头**:
```
X-Node-Key: {node_key}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 任务ID |

---

### 7.5 下载任务文件

**接口**: `GET /dispatch/task/:id/file`

**请求头**:
```
X-Node-Key: {node_key}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 任务ID |

---

### 7.6 上报任务状态

**接口**: `POST /dispatch/task/:id/status`

**请求头**:
```
X-Node-Key: {node_key}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| id | string | 任务ID |

**请求参数**:
```json
{
  "status": 2,
  "error_msg": ""
}
```

| 参数 | 类型 | 必需 | 说明 | 枚举值 |
|------|------|------|------|--------|
| status | int | 是 | 任务状态 | 2:打印中, 3:已完成, 4:已失败 |
| error_msg | string | 否 | 错误信息（status=4时必填） | - |

---

## 八、支付模块 (Payment)

### 8.1 创建支付订单

**接口**: `POST /payment/create`

**请求头**:
```
Authorization: Bearer {token}
```

**请求参数**:
```json
{
  "order_id": "PE202602190001"
}
```

---

### 8.2 支付回调 (mpay回调)

**接口**: `POST /payment/callback`

**说明**: 供 mpay 系统回调使用

---

### 8.3 查询支付状态

**接口**: `GET /payment/:order_id/status`

**请求头**:
```
Authorization: Bearer {token}
```

**路径参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| order_id | string | 订单号 |

---

## 九、管理后台模块 (Admin)

### 9.1 管理员登录

**接口**: `POST /admin/auth/login`

**请求参数**:
```json
{
  "username": "admin",
  "password": "password"
}
```

---

### 9.2 获取订单列表 (管理员)

**接口**: `GET /admin/orders`

**请求头**:
```
Authorization: Bearer {admin_token}
```

**查询参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码 |
| limit | int | 否 | 每页数量 |
| status | int | 否 | 订单状态 |
| start_date | string | 否 | 开始日期 |
| end_date | string | 否 | 结束日期 |

---

### 9.3 获取节点列表

**接口**: `GET /admin/dispatch/nodes`

**请求头**:
```
Authorization: Bearer {admin_token}
```

---

### 9.4 获取任务列表

**接口**: `GET /admin/dispatch/tasks`

**请求头**:
```
Authorization: Bearer {admin_token}
```

---

### 9.5 统计数据

**接口**: `GET /admin/stats`

**请求头**:
```
Authorization: Bearer {admin_token}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "today_orders": 100,
    "today_revenue": 500.00,
    "total_orders": 10000,
    "total_revenue": 50000.00,
    "online_nodes": 5
  }
}
```

---

**文档版本**：v1.0  
**创建日期**：2026-02-19
