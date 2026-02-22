# 问题解决文档：支付回调处理及金额提取问题修复

## 问题概述
1. **金额提取失败**：`WxPay.php` 无法识别 ¥0.01 格式的金额
2. **回调日志缺失**：`PayController.php` 缺少回调处理的日志记录
3. **回调报错**：`http://localhost/mpayNotify` 访问报错
4. **日志文件问题**：日志文件未生成，且希望所有日志保存在一个文件中
5. **Unicode编码问题**：日志中使用了Unicode编码，影响可读性
6. **订单匹配失败**：接收了手机的post通知但没有回调，订单状态一直为等待付款

## 解决方案

### 1. 修复金额提取失败问题
**文件**：`e:\ProgramProject\Builder\mpay\www\extend\payclient\WxPay.php`

**修改内容**：
- 增强了金额提取逻辑，支持多种格式的金额表示
- 修复了 ¥0.01 无法识别的问题
- 修改了金额判断逻辑，确保空金额或0金额能够正确处理

**关键修改**：
```php
// 提取金额 - 支持多种格式
$money = 0;

// 模式1: 匹配带"元"字的金额（最常用）
$patt_money = '/(\d+(?:\.\d{1,2})?)(?=元)/';
preg_match($patt_money, $this->msg, $info);
if ($info) {
    $money = $info[1];
} else {
    // 模式2: 匹配带¥符号的金额
    $patt_yuan = '/¥\s*(\d+(?:\.\d{1,2})?)/';
    preg_match($patt_yuan, $this->msg, $info_yuan);
    if ($info_yuan) {
        $money = $info_yuan[1];
    } else {
        // 模式3: 特殊情况 - 个人收款码到账
        if (preg_match('/个人收款码到账/', $this->msg)) {
            preg_match('/(\d+(?:\.\d{1,2})?)$/', $this->msg, $info_x);
            if ($info_x) {
                $money = $info_x[1];
                return ['type' => 1, 'money' => $money];
            } else {
                return [];
            }
        } else {
            // 模式4: 尝试提取任何数字金额
            preg_match('/(\d+(?:\.\d{1,2})?)/', $this->msg, $info_any);
            if ($info_any) {
                $money = $info_any[1];
            } else {
                return [];
            }
        }
    }
}

if (empty($money) || $money == '0') return [];
```

### 2. 增加回调日志记录
**文件**：`e:\ProgramProject\Builder\mpay\www\app\controller\PayController.php`

**修改内容**：
- 在 `mpayNotify` 方法中增加了详细的日志记录
- 确保日志目录存在，不存在则创建
- 将所有日志保存在一个文件中，方便查看
- 禁用 Unicode 编码，确保日志可读性
- 在 `payHeart` 方法中增加了详细的订单匹配日志

**关键修改**：
```php
// 记录回调日志
$logDir = root_path() . '/runtime/logs/';
if (!is_dir($logDir)) {
    mkdir($logDir, 0755, true);
}
$logFile = $logDir . 'mpay_notify.log';
$logContent = date('Y-m-d H:i:s') . ' - 回调数据: ' . json_encode($info, JSON_UNESCAPED_UNICODE) . "\n";
file_put_contents($logFile, $logContent, FILE_APPEND);
```

### 3. 修复回调报错问题
**文件**：`e:\ProgramProject\Builder\mpay\www\app\controller\PayController.php`

**修改内容**：
- 在 `mpayNotify` 方法中添加了对 `$config` 的检查，确保当 `PayAccount::getAccountConfig` 方法返回 `false` 时，代码不会尝试访问 `$config['payclass']`
- 添加了对 `$config['payclass']` 是否存在的检查，确保当插件配置错误时，代码不会尝试使用不存在的类名

**关键修改**：
```php
$config = PayAccount::getAccountConfig($data['aid'], $data['pid']);
if ($config === false) {
    $logContent = date('Y-m-d H:i:s') . ' - 监听收款配置错误' . "\n";
    file_put_contents($logFile, $logContent, FILE_APPEND);
    return '监听收款配置错误';
}
if (!isset($config['payclass'])) {
    $logContent = date('Y-m-d H:i:s') . ' - 插件配置错误，缺少 class_name' . "\n";
    file_put_contents($logFile, $logContent, FILE_APPEND);
    return '插件配置错误，缺少 class_name';
}
```

### 4. 修复订单匹配失败问题
**文件**：`e:\ProgramProject\Builder\mpay\www\app\controller\PayController.php`

**修改内容**：
- 在 `payHeart` 方法中修改了订单匹配逻辑，忽略渠道类型的差异，只匹配账号部分
- 解决了支付渠道不匹配的问题（如 wxpay1#19956218237 和 wxpay2#19956218237）

**关键修改**：
```php
// 支付渠道核对
// 忽略渠道类型的差异，只匹配账号部分
$order_channel = $cids[$order->cid];
$new_order_channel = $new_order['channel'];

// 提取账号部分
preg_match('/#(.*)$/', $order_channel, $order_account);
preg_match('/#(.*)$/', $new_order_channel, $new_order_account);

$is_channel = isset($order_account[1]) && isset($new_order_account[1]) && $order_account[1] == $new_order_account[1];
```

## 技术要点
1. **金额提取**：使用多种正则表达式模式匹配不同格式的金额表示
2. **日志记录**：确保日志目录存在，使用 `JSON_UNESCAPED_UNICODE` 选项禁用Unicode编码
3. **错误处理**：添加详细的错误检查和日志记录，确保代码的健壮性
4. **订单匹配**：忽略渠道类型的差异，只匹配账号部分，提高订单匹配的成功率

## 验证结果
- ✅ ¥0.01 金额能够正确识别
- ✅ 回调日志能够正确生成，且所有日志保存在一个文件中
- ✅ 日志中不再使用Unicode编码，提高可读性
- ✅ 订单能够正确匹配，回调处理正常
- ✅ 支付后订单状态能够正确更新

## 总结
通过以上修改，成功解决了支付回调处理中的多个问题，包括金额提取失败、日志记录缺失、回调报错、订单匹配失败等。修改后的代码更加健壮，能够正确处理各种格式的金额表示，并且提供了详细的日志记录，方便调试和问题排查。