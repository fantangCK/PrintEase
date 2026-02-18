# PrintEase Backend 印易自助 - 后台服务

印易自助打印后台服务，基于 NestJS + TypeScript 开发，提供 RESTful API。

## 技术栈

- **后端框架**: NestJS
- **开发语言**: TypeScript
- **数据库**: MySQL 8.0
- **ORM**: TypeORM
- **认证**: JWT
- **缓存**: Redis (待办)
- **容器化**: Docker

## 功能特性

### 1. 认证模块
- 用户登录认证
- JWT Token 管理
- 微信小程序登录
- 权限控制

### 2. 文件模块
- 文件上传
- 文件下载
- 文件信息管理
- 文件格式校验

### 3. 订单模块
- 订单创建
- 订单查询
- 订单状态更新
- 订单历史记录

### 4. 派单调度模块
- 打印节点注册
- 节点心跳保活
- 任务轮询
- 任务认领
- 打印状态上报

### 5. 支付模块
- 与 mpay 支付系统集成
- 支付订单创建
- 支付状态回调
- 支付记录查询

### 6. 用户模块
- 用户信息管理
- 用户历史订单
- 用户数据统计

## 项目结构

```
PrintEase-backend/
├── src/
│   ├── modules/
│   │   ├── auth/                    # 认证模块
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── jwt.strategy.ts
│   │   │   └── wechat.strategy.ts
│   │   ├── file/                    # 文件模块
│   │   │   ├── file.module.ts
│   │   │   ├── file.controller.ts
│   │   │   ├── file.service.ts
│   │   │   └── entities/
│   │   │       └── file.entity.ts
│   │   ├── order/                   # 订单模块
│   │   │   ├── order.module.ts
│   │   │   ├── order.controller.ts
│   │   │   ├── order.service.ts
│   │   │   └── entities/
│   │   │       └── order.entity.ts
│   │   ├── dispatch/                # 派单调度模块
│   │   │   ├── dispatch.module.ts
│   │   │   ├── dispatch.controller.ts
│   │   │   ├── dispatch.service.ts
│   │   │   └── entities/
│   │   │       ├── dispatch-node.entity.ts
│   │   │       └── print-task.entity.ts
│   │   ├── payment/                 # 支付模块
│   │   │   ├── payment.module.ts
│   │   │   ├── payment.controller.ts
│   │   │   ├── payment.service.ts
│   │   │   └── mpay.client.ts
│   │   └── user/                    # 用户模块
│   │       ├── user.module.ts
│   │       ├── user.controller.ts
│   │       ├── user.service.ts
│   │       └── entities/
│   │           └── user.entity.ts
│   ├── common/
│   │   ├── filters/
│   │   ├── guards/
│   │   ├── decorators/
│   │   ├── interceptors/
│   │   └── pipes/
│   ├── config/
│   │   ├── app.config.ts
│   │   ├── database.config.ts
│   │   └── mpay.config.ts
│   ├── database/
│   │   ├── migrations/
│   │   └── seeds/
│   ├── app.module.ts
│   └── main.ts
├── uploads/                         # 上传文件目录
├── logs/                            # 日志目录
├── test/                            # 测试文件
├── package.json
├── tsconfig.json
├── nest-cli.json
├── .env
├── .env.example
├── Dockerfile
├── Dockerfile.dev
└── README.md
```

## 快速开始

### 环境要求

- Node.js 18+
- npm 或 pnpm
- MySQL 8.0+
- Docker (可选)

### 安装依赖

```bash
cd PrintEase-backend
npm install
```

### 环境配置

创建 `.env` 文件：

```env
# 应用
NODE_ENV=development
PORT=3000

# 数据库
DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=password
DB_DATABASE=print_ease

# JWT
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=7d

# 微信小程序
WECHAT_APPID=your-appid
WECHAT_SECRET=your-secret

# mpay支付
MPAY_URL=http://localhost:8080
MPAY_KEY=your-mpay-key

# 文件上传
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=52428800
```

### 数据库初始化

```bash
# 创建数据库
npm run db:create

# 运行迁移
npm run db:migrate

# 运行种子数据 (可选)
npm run db:seed
```

### 开发环境运行

```bash
npm run start:dev
```

访问地址: http://localhost:3000

API 文档: http://localhost:3000/api/docs (待办)

### 生产环境构建

```bash
npm run build
npm run start:prod
```

### Docker 部署

```bash
# 开发环境
docker build -f Dockerfile.dev -t printease-backend:dev .
docker run -p 3000:3000 printease-backend:dev

# 生产环境
docker build -f Dockerfile -t printease-backend:latest .
docker run -p 3000:3000 printease-backend:latest
```

## API 接口

### 云印调度 API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/dispatch/node/register | 节点注册 |
| POST | /api/dispatch/node/heartbeat | 节点心跳 |
| GET | /api/dispatch/task/poll | 轮询任务 |
| POST | /api/dispatch/task/:id/claim | 认领任务 |
| GET | /api/dispatch/task/:id/file | 下载文件 |
| POST | /api/dispatch/task/:id/status | 上报状态 |

### 订单 API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/orders | 创建订单 |
| GET | /api/orders | 订单列表 |
| GET | /api/orders/:id | 订单详情 |
| PUT | /api/orders/:id/status | 更新订单状态 |

### 文件 API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/files/upload | 上传文件 |
| GET | /api/files/:id | 获取文件信息 |
| GET | /api/files/:id/download | 下载文件 |

### 认证 API

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | /api/auth/login | 用户登录 |
| POST | /api/auth/wechat | 微信小程序登录 |
| POST | /api/auth/refresh | 刷新 Token |

## 开发规范

### 代码规范

- 使用 TypeScript 严格模式
- 遵循 NestJS 最佳实践
- 使用 ESLint 进行代码检查
- 使用 Prettier 格式化代码

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

## 相关项目

- [PrintEase-uniapp](../PrintEase-uniapp) - 印易小程序
- [PrintEase-admin](../PrintEase-admin) - 印易管理后台
- [PrintEase-dispatch](../PrintEase-dispatch) - 云印调度
- [mpay](../mpay) - 印易支付系统

## License

MIT
