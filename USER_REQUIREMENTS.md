# 项目需求（个人优先）

> 助手应在开展规划、改代码、运行命令或回答本项目实现类问题前阅读本文件。  
> 与 Cursor 全局「用户规则」冲突时：**以本文件为准**（除非涉及安全/法律/系统强制约束）。

## 目标

- **产品方向**：`media_sort`（应用名「媒体整理」）面向本地相册的浏览与整理；当前代码已实现的核心是**本地相册浏览**能力。
- **已实现能力（以代码为准）**：
  - 使用 [`photo_manager`](https://pub.dev/packages/photo_manager) 读取系统相册中的**图片与视频**（`RequestType.common`），需系统相册权限；支持权限被拒绝/受限/有限访问等状态的引导与重试、打开系统设置。
  - **相册页**（[`lib/gallery/gallery_page.dart`](lib/gallery/gallery_page.dart)）：分页加载（每页 120 条）、接近列表底部自动加载更多、下拉刷新；按资源的 **`createDateTime`（通常更接近“拍摄时间”语义）** 排序，避免因“加入相册/复制入库”等行为导致旧照片意外跑到最前；AppBar 可在**日期倒序（最新在前）**与**日期正序（最旧在前）**之间切换；监听媒体库变更后刷新列表。
  - **相册列表页**（[`lib/albums/albums_page.dart`](lib/albums/albums_page.dart)）：以列表展示系统返回的相册（MediaStore bucket），展示**相册名称**、**数量**、**封面缩略图**与**路径**（优先取相册自身 `relativePathAsync`，否则回退到封面资源 `relativePath` 推导）；支持**点击进入相册内容页**，复用网格分页/排序/查看器能力。
  - **网格展示**（[`lib/gallery/media_grid.dart`](lib/gallery/media_grid.dart) + [`day_sections.dart`](lib/gallery/day_sections.dart)）：按**自然日**分组（以 `createDateTime` 转为本地日历日），每组标题 `YYYY-MM-DD`，四列网格。
  - **缩略图**（[`lib/gallery/media_thumbnail.dart`](lib/gallery/media_thumbnail.dart)）：约 320×320、质量 80；视频显示角标与时长。
  - **查看器**（[`lib/viewer/media_viewer_page.dart`](lib/viewer/media_viewer_page.dart)）：横向滑动浏览当前已加载列表；图片支持 `InteractiveViewer` 缩放；视频使用 [`video_player`](https://pub.dev/packages/video_player) 点击播放/暂停。
- **期望演进（待你补充优先级）**：名称强调「整理」，可在下方「当前迭代重点」写明下一步是否包含删除/移动/重命名/相册分类/导出等。

## 非目标（当前代码未覆盖）

- **无云端**：无账号、无同步、无远程 API。
- **无编辑写回**：当前无对系统相册内资源的删除、移动、复制、元数据修改等操作。
- **无多相册切换**：`getAssetPathList` 使用 `onlyAll: true`，仅「全部」相簿一条路径。
- **查看器范围**：大图/视频页仅针对**当前网格已加载的** `items` 列表分页，未实现「全库无缝加载到查看器」类逻辑。

## 技术栈与约束

- **框架**：Flutter（Material 3，`debugShowCheckedModeBanner: false`）。
- **语言 / SDK**：Dart，`environment.sdk: ^3.11.4`（见 [`pubspec.yaml`](pubspec.yaml)）。
- **主要依赖**：`photo_manager: ^3.0.0`，`video_player: ^2.9.2`，`cupertino_icons: ^1.0.8`；分析规范见 [`analysis_options.yaml`](analysis_options.yaml)（`flutter_lints`）。
- **入口与路由**：[`lib/main.dart`](lib/main.dart) → `GalleryPage`；查看器为 `Navigator` + `MaterialPageRoute`。
- **测试**：[`test/widget_test.dart`](test/widget_test.dart)  smoke：`MediaSortApp` 能构建且存在「相册」文案。

## 交互与协作偏好

- **文档与沟通**：与助手对话、本文件正文以**中文**为主。
- **Cursor 项目规则**：本仓库 `.cursor/rules/` 下另有始终生效规则（例如：需要用户选择时用弹窗提问；**禁止在本机执行** `flutter build ...` 系列打包命令）。若与本文件冲突，以你在上文「个人优先」区块声明的裁决为准，并应同步修改或删除冲突的规则文件。

## 禁止事项

- **本机打包**：不在用户机器上执行任何 `flutter build apk/appbundle/ipa/web/windows/macos/linux` 等（与仓库规则一致）；允许 `flutter pub get`、`flutter analyze`、`flutter test` 等。
- **范围**：改动以完成任务所需为限，避免无关大重构；不擅自删除本文件中「非目标」所描述的安全边界（如未授权就假定可写相册）除非需求变更已写入本文件。

## 当前迭代重点

- （由你填写：例如「先做相册内整理动作」「先做 Web/桌面端适配」「优化大相册性能」等。）
- 产品文案可统一：应用 `title` 为「媒体整理」，首页 AppBar 为「相册」——若需一致可在迭代中改文案或拆分场景。
