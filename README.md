# Paperclip 本地中文补丁包

这是 Paperclip 的本地中文补丁包。

它不是把原作者代码改成另一个项目，而是把本地中文化和 Windows 运行修复整理成可重复应用的补丁。以后原作者更新 Paperclip，你可以先下载新版，再把这里的补丁套上去。

原项目：

- https://github.com/paperclipai/paperclip

## 文件说明

- `0001-local-zh-ui-and-windows-fixes.patch`
  - 必选补丁。
  - 加入本地中文 UI 翻译层。
  - 包含 Windows 本地运行相关的小修复。

- `0002-optional-codex-model-default.patch`
  - 可选补丁。
  - 用来避免 Paperclip 默认使用 `gpt-5.3-codex-spark`。
  - 只有你的中转站没有这个模型时才建议套。

- `0003-comprehensive-zh-ui-text.patch`
  - 必选补丁。
  - 补齐任务详情、暂停弹窗、收件箱、任务看板、新建任务窗口、搜索框、属性选择器等更多中文界面文案。

- `apply-local-zh.ps1`
  - Windows 一键应用脚本。
  - 会先检查补丁能不能套。
  - 已经套过的补丁会自动跳过。
  - 可以用于 Git 仓库，也可以用于直接下载解压出来的 Paperclip 目录。

## 怎么用

方式一：在 Paperclip 目录根部运行：

```powershell
.\apply-local-zh.ps1
```

如果这个补丁包放在 Paperclip 的 `patches/local-zh` 目录里，就运行：

```powershell
.\patches\local-zh\apply-local-zh.ps1
```

方式二：补丁包单独下载，不复制进 Paperclip 目录，直接指定 Paperclip 路径：

```powershell
.\apply-local-zh.ps1 -PaperclipRepo "C:\path\to\paperclip"
```

如果你的中转站不支持 `gpt-5.3-codex-spark`，加上可选参数：

```powershell
.\apply-local-zh.ps1 -PaperclipRepo "C:\path\to\paperclip" -IncludeCodexModelDefault
```

只检查补丁能不能套，不真正修改文件：

```powershell
.\apply-local-zh.ps1 -PaperclipRepo "C:\path\to\paperclip" -CheckOnly
```

## 推荐升级流程

1. 下载或更新原作者新版 Paperclip。
2. 下载这个补丁包。
3. 运行：

```powershell
.\apply-local-zh.ps1 -PaperclipRepo "C:\path\to\new-paperclip"
```

4. 如果需要适配你的中转模型，再加参数：

```powershell
.\apply-local-zh.ps1 -PaperclipRepo "C:\path\to\new-paperclip" -IncludeCodexModelDefault
```

5. 启动 Paperclip：

```powershell
pnpm dev
```

## 注意

- 这个补丁包是给本地使用的，不建议直接提交给原作者主仓库。
- 如果原作者改动了同一批文件，补丁可能会提示不能自动应用。那时需要重新生成新版中文补丁。
- 归档公司、恢复公司、收件箱状态这些属于 Paperclip 本地数据库，不在这个补丁包里，也不会上传到 GitHub。
