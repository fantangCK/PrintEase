# PrintEase Dispatch 印易自助 - 云印调度

印易自助打印云印调度客户端，基于 Python 3.10+ + Tkinter 开发，负责本地打印任务的调度和执行。

## 技术栈

- **编程语言**: Python 3.10+
- **GUI 框架**: Tkinter (Python 内置)
- **HTTP 客户端**: requests
- **配置管理**: PyYAML
- **跨平台打印**:
  - Windows: pywin32 / win32print
  - Linux/macOS: pycups / lp 命令

## 功能特性

### 1. 节点管理
- 节点注册与认证
- 心跳保活（默认 30 秒）
- 节点状态监控
- 节点信息展示

### 2. 任务调度
- 自动轮询待打印任务（默认 5 秒）
- 任务认领与分配
- 任务队列管理
- 任务状态追踪

### 3. 文件下载
- 打印文件自动下载
- 下载进度展示
- 临时文件管理
- 文件完整性校验

### 4. 打印执行
- 跨平台打印支持（Windows/Linux/macOS）
- 打印机列表查询
- 默认打印机配置
- 打印参数设置
- 打印进度监控

### 5. 状态上报
- 打印状态实时上报
- 错误日志记录
- 失败重试机制
- 打印完成通知

### 6. GUI 界面
- 主窗口展示
- 任务列表组件
- 打印机列表组件
- 日志查看组件
- 设置对话框
- 关于对话框

## 项目结构

```
PrintEase-dispatch/
├── src/
│   ├── __init__.py
│   ├── main.py                  # 程序入口
│   ├── api/                     # API客户端
│   │   ├── __init__.py
│   │   ├── client.py            # HTTP客户端
│   │   ├── node.py              # 节点相关API
│   │   └── task.py              # 任务相关API
│   ├── config/                  # 配置管理
│   │   ├── __init__.py
│   │   └── settings.py
│   ├── gui/                     # GUI界面 (Tkinter)
│   │   ├── __init__.py
│   │   ├── main_window.py       # 主窗口
│   │   ├── components/
│   │   │   ├── task_list.py     # 任务列表组件
│   │   │   ├── printer_list.py  # 打印机列表组件
│   │   │   └── log_view.py      # 日志组件
│   │   └── dialogs/
│   │       ├── settings_dialog.py
│   │       └── about_dialog.py
│   ├── dispatch/                # 调度逻辑
│   │   ├── __init__.py
│   │   ├── heartbeat.py         # 心跳
│   │   ├── poller.py            # 任务轮询
│   │   └── scheduler.py         # 调度器
│   ├── print/                   # 打印执行
│   │   ├── __init__.py
│   │   ├── base.py              # 打印接口定义
│   │   ├── windows.py           # Windows实现
│   │   ├── linux.py             # Linux实现 (待办)
│   │   └── darwin.py            # macOS实现
│   ├── task/                    # 任务管理
│   │   ├── __init__.py
│   │   ├── manager.py           # 任务管理器
│   │   └── worker.py            # 任务工作线程
│   └── utils/                   # 工具函数
│       ├── __init__.py
│       └── logger.py
├── configs/
│   └── config.yaml              # 配置文件
├── temp/                        # 临时文件目录
├── logs/                        # 日志目录
├── requirements.txt             # Python依赖
├── Dockerfile                   # Docker镜像 (可选，主要用于无头模式)
├── README.md
└── .gitignore
```

## 快速开始

### 环境要求

- Python 3.10+
- pip

### 安装依赖

```bash
cd PrintEase-dispatch

# 创建虚拟环境 (推荐)
python -m venv venv

# 激活虚拟环境
# Windows
venv\Scripts\activate
# Linux/macOS
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 配置文件

创建 `configs/config.yaml` 文件：

```yaml
server:
  backend_url: "http://localhost:3000"
  poll_interval: 5s
  heartbeat_interval: 30s

node:
  name: "打印节点-01"
  key: "your-node-secret-key"

print:
  default_printer: ""
  temp_dir: "./temp"

log:
  level: "info"
  file: "./logs/dispatch.log"
```

### 运行程序

```bash
python src/main.py
```

### Docker 部署（可选）

注意：云印调度通常不建议容器化，因为需要访问本地打印机和 GUI 界面。但在无头模式或仅作测试时可以使用：

```bash
docker build -t printease-dispatch:latest .
docker run -v /dev/usb/lp0:/dev/usb/lp0 printease-dispatch:latest
```

## 核心流程

```
1. 启动 → 显示GUI → 节点注册
   ↓
2. 心跳保活 (每30秒) + GUI更新节点状态
   ↓
3. 任务轮询 (每5秒) + GUI更新任务列表
   ↓
4. 认领任务 → 下载文件 → GUI显示下载进度
   ↓
5. 调用系统打印API → GUI显示打印进度
   ↓
6. 上报打印状态 (打印中/完成/失败) + GUI更新
```

## 跨平台打印支持

| 操作系统 | 打印方案 | 依赖库 |
|----------|----------|--------|
| Windows | Win32 Print API | pywin32 |
| Linux | CUPS | pycups |
| macOS | CUPS | pycups |

## API 接口

云印调度通过 HTTP API 与印易后台通信：

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/dispatch/node/register | 节点注册 |
| POST | /api/dispatch/node/heartbeat | 节点心跳 |
| GET | /api/dispatch/task/poll | 轮询任务 |
| POST | /api/dispatch/task/:id/claim | 认领任务 |
| GET | /api/dispatch/task/:id/file | 下载文件 |
| POST | /api/dispatch/task/:id/status | 上报状态 |

## 开发规范

### 代码规范

- 遵循 PEP 8 代码风格
- 使用类型注解 (Type Hints)
- 编写清晰的文档字符串
- 使用 logging 记录日志

### Git 提交规范

```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建/工具相关
```

## requirements.txt

```
requests>=2.31.0
PyYAML>=6.0.1
pywin32>=306 ; sys_platform == 'win32'
pycups>=2.0.1 ; sys_platform == 'linux' or sys_platform == 'darwin'
```

## 常见问题

**Q: 云印调度无法连接后端？**
A: 检查 `configs/config.yaml` 中的 backend_url 配置是否正确。

**Q: 找不到打印机？**
A: 确保打印机已正确连接并安装驱动程序，检查操作系统打印机设置。

**Q: Windows 打印失败？**
A: 确保已安装 pywin32 依赖，检查是否有足够的权限访问打印机。

**Q: 如何修改节点名称？**
A: 在 `configs/config.yaml` 中修改 node.name 配置，重启程序生效。

## 相关项目

- [PrintEase-uniapp](../PrintEase-uniapp) - 印易小程序
- [PrintEase-admin](../PrintEase-admin) - 印易管理后台
- [PrintEase-backend](../PrintEase-backend) - 印易后台
- [mpay](../mpay) - 印易支付系统

## License

MIT
