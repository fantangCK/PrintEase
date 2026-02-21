# PrintEase 印易 - 商户 API 使用文档

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

## 四、商户打印任务 API

### 4.1 获取所有打印任务

**接口**: `GET /api/merchant/tasks`

**描述**: 获取该商户的所有打印任务

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
      "id": "PT202502190001",
      "orderId": "PE202502190001",
      "merchantId": 1,
      "fileId": 1,
      "printParams": {
        "copies": 1,
        "colorType": 0,
        "doubleSided": 0,
        "paperSize": "A4"
      },
      "status": 0,
      "createdAt": "2025-02-19T10:00:00.000Z",
      "order": { ... },
      "file": { ... }
    }
  ]
}
```

---

### 4.2 获取待处理的打印任务

**接口**: `GET /api/merchant/tasks/pending`

**描述**: 获取状态为「待分配」的打印任务

**请求 Header**:
```
x-api-key: {你的API Key}
```

**响应**:
同 4.1，但只返回 `status = 0`（待分配）的任务

---

### 4.3 获取打印任务详情

**接口**: `GET /api/merchant/tasks/:id`

**描述**: 获取指定打印任务的详细信息

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
    "id": "PT202502190001",
    "orderId": "PE202502190001",
    "merchantId": 1,
    "fileId": 1,
    "printParams": {
      "copies": 1,
      "colorType": 0,
      "doubleSided": 0,
      "paperSize": "A4",
      "printQuality": "normal"
    },
    "status": 0,
    "errorMsg": null,
    "startedAt": null,
    "completedAt": null,
    "createdAt": "2025-02-19T10:00:00.000Z",
    "updatedAt": "2025-02-19T10:00:00.000Z",
    "order": {
      "id": "PE202502190001",
      "userId": 1,
      "totalPages": 5,
      "copies": 1,
      "totalAmount": 0.5,
      "status": 1,
      "remark": "请快速打印",
      "createdAt": "2025-02-19T10:00:00.000Z"
    },
    "file": {
      "id": 1,
      "fileName": "test.pdf",
      "filePath": "uploads/.../test.pdf",
      "convertedPdfPath": "uploads/.../test.pdf",
      "fileSize": 102400,
      "totalPages": 5
    }
  }
}
```

---

### 4.4 开始打印任务

**接口**: `PUT /api/merchant/tasks/:id/start`

**描述**: 标记任务开始打印

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
    "id": "PT202502190001",
    "status": 2,
    "startedAt": "2025-02-19T10:05:00.000Z"
  }
}
```

---

### 4.5 完成打印任务

**接口**: `PUT /api/merchant/tasks/:id/complete`

**描述**: 标记任务打印完成

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
    "id": "PT202502190001",
    "status": 3,
    "completedAt": "2025-02-19T10:10:00.000Z"
  }
}
```

---

### 4.6 标记打印任务失败

**接口**: `PUT /api/merchant/tasks/:id/fail`

**描述**: 标记任务打印失败

**请求 Header**:
```
x-api-key: {你的API Key}
Content-Type: application/json
```

**路径参数**:
- `id`: 打印任务 ID

**请求 Body**:
```json
{
  "errorMsg": "打印机缺纸"
}
```

**响应**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "id": "PT202502190001",
    "status": 4,
    "errorMsg": "打印机缺纸"
  }
}
```

---

## 五、打印任务状态

| 值 | 说明 |
|----|------|
| 0 | 待分配（待打印） |
| 1 | 已分配 |
| 2 | 打印中 |
| 3 | 已完成 |
| 4 | 已失败 |

---

## 六、下载打印文件

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

## 七、完整工作流程示例

### 7.1 商户接收打印任务流程

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

### 7.2 代码示例（Python）

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

## 八、错误码

| HTTP 状态码 | 说明 |
|------------|------|
| 401 | 无效的 API Key |
| 404 | 任务不存在 |
| 500 | 服务器内部错误 |

---

## 九、关键代码位置

- **商户实体**：`printease-backend/src/modules/user/entities/merchant.entity.ts`
- **商户服务**：`printease-backend/src/modules/user/user.service.ts`
- **商户打印任务控制器**：`printease-backend/src/modules/dispatch/dispatch.controller.ts`
- **打印任务实体**：`printease-backend/src/modules/dispatch/entities/print-task.entity.ts`

---

**文档版本**：v1.0  
**创建日期**：2026-02-21
