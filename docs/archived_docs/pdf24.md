# PDF24-DocTool.exe Python 自动化脚本解决方案

本文档提供使用 Python 脚本自动化调用 `pdf24-DocTool.exe` 工具的完整解决方案，涵盖文档转 PDF、打印功能及其他常用操作。

## 1. 前置要求

### 1.1 安装 PDF24 Creator
- 下载并安装 [PDF24 Creator 11](https://tools.pdf24.org/creator)
- 确保 `pdf24-DocTool.exe` 可执行文件位于系统 PATH 中，或记录其完整路径（通常为 `C:\Program Files\PDF24\pdf24-DocTool.exe`）

### 1.2 Python 环境
- Python 3.6+
- 标准库：`subprocess`, `os`, `pathlib`

## 2. 核心工具类

```python
import subprocess
import os
from pathlib import Path
from typing import List, Optional, Union

class PDF24DocTool:
    """PDF24 DocTool 自动化工具类"""
    
    def __init__(self, doctool_path: str = None):
        """
        初始化工具
        
        Args:
            doctool_path: pdf24-DocTool.exe 的完整路径
                         如果为 None，则尝试从默认位置查找
        """
        if doctool_path is None:
            # 尝试常见安装路径
            default_paths = [
                r"C:\Program Files\PDF24\pdf24-DocTool.exe",
                r"C:\Program Files (x86)\PDF24\pdf24-DocTool.exe"
            ]
            for path in default_paths:
                if os.path.exists(path):
                    self.doctool_path = path
                    break
            else:
                raise FileNotFoundError("未找到 pdf24-DocTool.exe，请指定完整路径")
        else:
            self.doctool_path = doctool_path
            
    def _run_command(self, args: List[str], capture_output: bool = True) -> subprocess.CompletedProcess:
        """执行命令行命令"""
        cmd = [self.doctool_path] + args
        try:
            result = subprocess.run(
                cmd,
                capture_output=capture_output,
                text=True,
                check=False  # 不自动抛出异常，由调用者处理
            )
            return result
        except Exception as e:
            raise RuntimeError(f"执行命令失败: {e}")

    def convert_to_pdf(
        self,
        input_files: Union[str, List[str]],
        output_file: str = None,
        output_dir: str = None,
        profile: str = "default/good",
        sort_files: bool = False,
        delete_originals: bool = False
    ) -> bool:
        """
        将文档转换为 PDF
        
        Args:
            input_files: 输入文件路径（单个文件或文件列表）
            output_file: 输出 PDF 文件路径（可选）
            output_dir: 输出目录（可选）
            profile: 转换配置文件（default/low, default/medium, default/good, default/high, default/best）
            sort_files: 是否按文件名排序
            delete_originals: 是否删除原始文件
            
        Returns:
            bool: 转换是否成功
        """
        # 处理输入文件
        if isinstance(input_files, str):
            files = [input_files]
        else:
            files = input_files
            
        # 验证输入文件存在
        for file in files:
            if not os.path.exists(file):
                raise FileNotFoundError(f"输入文件不存在: {file}")
        
        # 构建命令参数
        args = ["-convertToPDF"]
        
        if profile:
            args.extend(["-profile", profile])
            
        if output_file:
            args.extend(["-outputFile", output_file])
            
        if output_dir:
            args.extend(["-outputDir", output_dir])
            
        if sort_files:
            args.append("-sort")
            
        if delete_originals:
            args.append("-deleteFiles")
            
        args.extend(files)
        
        # 执行命令
        result = self._run_command(args)
        return result.returncode == 0

    def print_files(
        self,
        input_files: Union[str, List[str]],
        printer_name: str = None
    ) -> bool:
        """
        打印文件
        
        Args:
            input_files: 要打印的文件路径（单个文件或文件列表）
            printer_name: 打印机名称（可选，默认使用系统默认打印机）
            
        Returns:
            bool: 打印命令是否成功执行
        """
        if isinstance(input_files, str):
            files = [input_files]
        else:
            files = input_files
            
        # 验证输入文件存在
        for file in files:
            if not os.path.exists(file):
                raise FileNotFoundError(f"输入文件不存在: {file}")
                
        # 构建命令参数
        args = ["-shellPrint"]
        
        if printer_name:
            args.extend(["-printerName", printer_name])
            
        args.extend(files)
        
        # 执行命令（不捕获输出，因为打印是异步操作）
        result = self._run_command(args, capture_output=False)
        return result.returncode == 0

    def join_pdfs(
        self,
        input_files: List[str],
        output_file: str,
        sort_files: bool = True,
        bookmarks: str = "keep"  # keep, clear, create
    ) -> bool:
        """
        合并多个 PDF 文件
        
        Args:
            input_files: PDF 文件列表
            output_file: 输出文件路径
            sort_files: 是否按文件名排序
            bookmarks: 书签处理方式
            
        Returns:
            bool: 合并是否成功
        """
        # 验证输入文件
        for file in input_files:
            if not os.path.exists(file):
                raise FileNotFoundError(f"输入文件不存在: {file}")
                
        # 构建命令
        args = ["-join"]
        
        if sort_files:
            args.append("-sort")
            
        if bookmarks in ["keep", "clear", "create"]:
            args.extend(["-bookmarks", bookmarks])
            
        args.extend(["-outputFile", output_file])
        args.extend(input_files)
        
        result = self._run_command(args)
        return result.returncode == 0

    def compress_pdf(
        self,
        input_file: str,
        output_file: str = None,
        output_dir: str = None,
        dpi: int = 144,
        image_quality: int = 75,
        color_model: str = ""
    ) -> bool:
        """
        压缩 PDF 文件
        
        Args:
            input_file: 输入 PDF 文件
            output_file: 输出文件路径（可选）
            output_dir: 输出目录（可选）
            dpi: DPI 值（默认 144）
            image_quality: 图像质量百分比（1-100，默认 75）
            color_model: 颜色模型（"", "rgb", "cmyk", "gray"）
            
        Returns:
            bool: 压缩是否成功
        """
        if not os.path.exists(input_file):
            raise FileNotFoundError(f"输入文件不存在: {input_file}")
            
        args = ["-compress"]
        
        if dpi != 144:
            args.extend(["-dpi", str(dpi)])
            
        if image_quality != 75:
            args.extend(["-imageQuality", str(image_quality)])
            
        if color_model:
            args.extend(["-colorModel", color_model])
            
        if output_file:
            args.extend(["-outputFile", output_file])
            
        if output_dir:
            args.extend(["-outputDir", output_dir])
            
        args.append(input_file)
        
        result = self._run_command(args)
        return result.returncode == 0
```

## 3. 使用示例

### 3.1 基本文档转 PDF

```python
# 初始化工具
pdf_tool = PDF24DocTool()

# 单个文件转换
success = pdf_tool.convert_to_pdf(
    input_files="document.docx",
    output_file="output.pdf",
    profile="default/good"
)

if success:
    print("转换成功！")
else:
    print("转换失败！")
```

### 3.2 批量文档转 PDF

```python
# 批量转换多个文件
input_files = ["report.docx", "presentation.pptx", "data.xlsx"]
success = pdf_tool.convert_to_pdf(
    input_files=input_files,
    output_dir="C:/Converted_PDFs",
    sort_files=True
)
```

### 3.3 打印功能

```python
# 使用默认打印机打印
pdf_tool.print_files("document.pdf")

# 指定打印机打印
pdf_tool.print_files("document.pdf", printer_name="HP_LaserJet_Pro")
```

### 3.4 高级功能组合

```python
# 转换并压缩 PDF
def convert_and_compress(input_file: str, output_file: str):
    """转换文档为 PDF 并压缩"""
    temp_pdf = "temp_converted.pdf"
    
    # 第一步：转换为 PDF
    if not pdf_tool.convert_to_pdf(input_file, temp_pdf):
        return False
        
    # 第二步：压缩 PDF
    success = pdf_tool.compress_pdf(
        temp_pdf,
        output_file=output_file,
        dpi=120,
        image_quality=60
    )
    
    # 清理临时文件
    if os.path.exists(temp_pdf):
        os.remove(temp_pdf)
        
    return success

# 使用示例
convert_and_compress("large_document.docx", "compressed_output.pdf")
```

## 4. 错误处理和最佳实践

### 4.1 错误处理

```python
try:
    pdf_tool = PDF24DocTool()
    success = pdf_tool.convert_to_pdf("nonexistent.docx", "output.pdf")
    if not success:
        print("转换过程出现错误，请检查输入文件和权限")
except FileNotFoundError as e:
    print(f"文件错误: {e}")
except RuntimeError as e:
    print(f"运行时错误: {e}")
```

### 4.2 最佳实践

1. **路径处理**：始终使用绝对路径或验证相对路径
2. **文件验证**：在执行前验证输入文件存在且可读
3. **输出目录**：确保输出目录存在且有写入权限
4. **资源清理**：及时清理临时文件
5. **错误日志**：记录详细的错误信息用于调试

### 4.3 配置管理

```python
# 配置字典示例
PDF24_CONFIG = {
    "profiles": {
        "web": {"profile": "default/low", "dpi": 96},
        "print": {"profile": "default/high", "dpi": 300},
        "archive": {"profile": "default/best", "dpi": 600}
    },
    "default_output_dir": "C:/PDF_Output"
}

def convert_with_config(input_file: str, config_name: str = "web"):
    """使用预定义配置进行转换"""
    config = PDF24_CONFIG["profiles"][config_name]
    output_dir = PDF24_CONFIG["default_output_dir"]
    
    # 创建输出目录
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    output_file = os.path.join(
        output_dir, 
        f"{Path(input_file).stem}_{config_name}.pdf"
    )
    
    return pdf_tool.convert_to_pdf(
        input_file,
        output_file=output_file,
        profile=config["profile"]
    )
```

## 5. 常见问题解决

### 5.1 权限问题
- 确保 Python 脚本以足够权限运行
- 输出目录需要写入权限

### 5.2 依赖问题
- Office 文档转换需要 Microsoft Office 或 LibreOffice 安装
- 某些格式可能需要额外的编解码器

### 5.3 性能优化
- 对于大量文件，考虑分批处理
- 使用合适的配置文件平衡质量和文件大小

## 6. 扩展功能

可以根据需要扩展工具类，添加以下功能：
- OCR 文字识别集成
- PDF 加密/解密
- 页面提取和分割
- 元数据编辑
- 批量重命名和组织

这个解决方案提供了完整的 PDF24-DocTool.exe Python 自动化框架，可以根据具体需求进行定制和扩展。