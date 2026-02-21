# PrintEase 印易 - PDF 预览和文件处理文档

## 一、概述

本文档详细介绍 PrintEase 中的文件处理流程，包括文件上传、格式转换、PDF 预览、文件下载等功能。

---

## 二、文件处理架构

### 2.1 架构图

```
用户上传文件
    ↓
后端接收文件
    ↓
检查文件类型
    ↓
┌───────────────┬───────────────┐
│   PDF 文件    │  非 PDF 文件   │
└───────┬───────┴───────┬───────┘
        │               │
        ↓               ↓
   直接使用      调用转换服务
        │               │
        └───────┬───────┘
                ↓
        保存文件信息到数据库
                ↓
        返回文件信息给前端
```

---

## 三、文件上传

### 3.1 支持的文件格式

| 格式 | 扩展名 | 说明 |
|------|--------|------|
| PDF | `.pdf` | 可直接打印 |
| Word | `.doc`, `.docx` | 需转换为 PDF |
| Excel | `.xls`, `.xlsx` | 需转换为 PDF |
| PowerPoint | `.ppt`, `.pptx` | 需转换为 PDF |
| 文本 | `.txt` | 需转换为 PDF |
| 图片 | `.jpg`, `.jpeg`, `.png`, `.gif` | 需转换为 PDF |

### 3.2 上传流程

1. **前端选择文件**
   - 使用 `uni.chooseMessageFile` 或 `uni.chooseImage` 选择文件
   - 限制文件大小（建议不超过 50MB）

2. **上传到后端**
   - 调用 `POST /api/files/upload` 接口
   - 使用 `multipart/form-data` 格式

3. **后端处理**
   - 接收文件并保存到服务器（`uploads/` 目录）
   - 提取文件信息（文件名、大小、类型、扩展名）
   - 如果是 PDF，尝试解析页数
   - 保存文件信息到数据库
   - 返回文件信息

### 3.3 后端文件存储

- **存储目录**：`uploads/`
- **文件命名**：`{timestamp}_{random}.{ext}`
- **目录结构**：
  ```
  uploads/
  ├── 2025/
  │   ├── 02/
  │   │   ├── 19/
  │   │   │   ├── 1234567890_abc123.pdf
  │   │   │   └── 1234567891_def456.docx
  ```

---

## 四、文件转换

### 4.1 转换服务

使用 Python + LibreOffice 进行文件格式转换。

**转换服务位置**：`PrintEase-backend/converter/`

### 4.2 转换流程

1. **前端触发转换**
   - 检查文件扩展名，如果不是 `.pdf` 则显示转换按钮
   - 用户点击「转换为 PDF」按钮

2. **后端处理**
   - 调用转换服务
   - 将原始文件转换为 PDF
   - 保存转换后的 PDF 文件
   - 更新数据库中的文件记录，添加 `convertedPdfPath` 字段

3. **前端等待转换完成**
   - 显示转换进度
   - 轮询文件状态或接收 WebSocket 通知
   - 转换完成后显示预览按钮

### 4.3 转换后文件名处理

**重要**：转换后文件信息中的文件名会更新为 PDF 文件名，但前端显示时需要注意：
- 显示给用户的文件名保持原始文件名（如 `document.docx`）
- 实际预览和下载使用转换后的 PDF 文件
- 文件信息字段：
  ```typescript
  {
    fileName: "document.docx",           // 原始文件名（显示给用户）
    filePath: "uploads/.../document.docx", // 原始文件路径
    convertedPdfPath: "uploads/.../document.pdf" // 转换后 PDF 路径
  }
  ```

---

## 五、PDF 预览

### 5.1 预览时机和位置

| 页面 | 是否显示预览 | 说明 |
|------|-------------|------|
| 上传页面 | ❌ 否 | 已取消，避免不必要的预览 |
| 转换页面 | ✅ 是 | 转换完成后显示预览 |
| 订单创建页面 | ✅ 是 | 文件信息区域显示预览 |
| 订单列表（待打印） | ✅ 是 | 每个订单显示文件预览 |
| 订单详情页面 | ✅ 是 | 文件信息卡片显示预览 |

### 5.2 预览文件选择逻辑

```typescript
function getPreviewFile(file) {
  // 优先使用转换后的 PDF
  if (file.convertedPdfPath) {
    return file.convertedPdfPath;
  }
  // 否则使用原始文件（仅 PDF）
  if (file.fileExt === 'pdf') {
    return file.filePath;
  }
  // 无法预览
  return null;
}
```

### 5.3 小程序预览实现

#### 5.3.1 预览步骤

1. **获取下载 URL**
   ```typescript
   const downloadUrl = `${baseUrl}/api/files/${fileId}/download`;
   ```

2. **下载文件**
   ```typescript
   uni.downloadFile({
     url: downloadUrl,
     success: (res) => {
       if (res.statusCode === 200) {
         // 下载成功，打开文件
         openDocument(res.tempFilePath);
       }
     }
   });
   ```

3. **打开文件**
   ```typescript
   uni.openDocument({
     filePath: tempFilePath,
     fileType: 'pdf',
     success: () => {
       console.log('打开文档成功');
     }
   });
   ```

#### 5.3.2 关键注意事项

1. **下载 URL 必须包含 `/api` 前缀**
   - ✅ 正确：`http://localhost:3000/api/files/1/download`
   - ❌ 错误：`http://localhost:3000/files/1/download`

2. **协议必须是 `http` 或 `https`**
   - 小程序不支持其他协议

3. **下载接口不需要认证**
   - 为了小程序下载方便，移除了下载接口的 JWT 认证要求

4. **文件名显示**
   - 显示给用户的文件名保持原始文件名
   - 实际预览使用转换后的 PDF

### 5.4 预览按钮显示条件

```typescript
const canPreview = computed(() => {
  // 有转换后的 PDF，或者是 PDF 文件
  return !!(file.convertedPdfPath || file.fileExt === 'pdf');
});
```

---

## 六、文件下载

### 6.1 下载接口

**接口**：`GET /api/files/:id/download`

**认证**：不需要

**响应**：文件流

### 6.2 下载 URL 生成

后端在 `file.controller.ts` 中提供 `getDownloadUrl` 方法：

```typescript
private getDownloadUrl(fileId: number): string {
  const baseUrl = this.configService.get<string>('APP_BASE_URL', 'http://localhost:3000');
  return `${baseUrl}/api/files/${fileId}/download`;
}
```

### 6.3 前端下载实现

```typescript
async function downloadFile(fileId: number, fileName: string) {
  try {
    const res = await uni.downloadFile({
      url: `${baseUrl}/api/files/${fileId}/download`,
    });
    
    if (res.statusCode === 200) {
      uni.saveFile({
        tempFilePath: res.tempFilePath,
        success: (saveRes) => {
          uni.showToast({
            title: '下载成功',
            icon: 'success'
          });
        }
      });
    }
  } catch (error) {
    console.error('下载失败:', error);
  }
}
```

---

## 七、关键代码位置

### 7.1 后端

- **文件控制器**：`printease-backend/src/modules/file/file.controller.ts`
  - 文件上传
  - 文件下载
  - 下载 URL 生成

- **文件服务**：`printease-backend/src/modules/file/file.service.ts`
  - 文件保存
  - 文件信息处理

- **转换服务**：`printease-backend/src/modules/conversion/conversion.service.ts`
  - 文件转换逻辑

- **转换脚本**：`printease-backend/converter/converter.py`
  - Python 转换脚本

### 7.2 前端

- **上传页面**：`printease-uniapp/src/pages/upload/index.vue`
  - 文件选择和上传

- **转换页面**：`printease-uniapp/src/pages/upload/converting.vue`
  - 转换进度显示
  - 预览功能

- **订单创建页面**：`printease-uniapp/src/pages/order/create.vue`
  - 文件信息展示
  - 预览功能

- **订单详情页面**：`printease-uniapp/src/pages/order/detail.vue`
  - 文件信息卡片
  - 预览功能

- **文件 API**：`printease-uniapp/src/api/file.ts`
  - 文件上传
  - 文件下载

---

## 八、常见问题

### 8.1 下载失败：协议必须是 http 或 https

**问题**：
```
downloadFile:fail downloadFile protocol must be http or https
```

**原因**：
- 下载 URL 缺少协议（如 `//localhost:3000/...`）
- 或使用了非 http/https 协议

**解决**：
- 确保下载 URL 包含完整的 `http://` 或 `https://` 协议
- 检查后端 `getDownloadUrl` 方法是否正确返回完整 URL

### 8.2 下载失败：Cannot GET /files/xx/download

**问题**：
```
Cannot GET /files/xx/download
```

**原因**：
- 下载 URL 缺少 `/api` 前缀

**解决**：
- 确保下载 URL 格式为 `/api/files/{id}/download`
- 检查后端是否正确添加了 `/api` 前缀

### 8.3 没有预览按钮

**问题**：
- 文件已转换，但没有显示预览按钮

**原因**：
- `convertedPdfPath` 字段为空
- 或文件名后缀判断错误

**解决**：
- 检查文件信息中是否有 `convertedPdfPath` 字段
- 检查 `canPreview` 计算属性逻辑是否正确

### 8.4 文件名显示错误

**问题**：
- 转换后文件名显示为 PDF 文件名，而不是原始文件名

**解决**：
- 确保显示给用户的是 `fileName` 字段（原始文件名）
- 实际预览和下载使用 `convertedPdfPath` 字段

---

**文档版本**：v1.0  
**创建日期**：2026-02-19
