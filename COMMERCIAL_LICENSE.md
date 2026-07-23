# UyaliBeautySDK Commercial License Guide

This page explains how UyaliBeautySDK licensing works. It is not a License file,
price quote, or standalone grant of commercial rights. Commercial rights arise
only after purchase or written agreement and are limited by the applicable
order, signed License file, [Terms of Service](https://uyalibeauty.com/terms),
and [SDK License Agreement](LICENSE.md).

[中文说明](#中文说明)

## License overview

| Mode | Enabled capabilities | Production and commercial use |
|---|---|---|
| Free | `white` (whitening), `skin` (smoothing) | Allowed without a License file |
| Evaluation | Other capabilities for 120 seconds after each engine instance is created | Development and evaluation only |
| Commercial | Modules and features expressly listed in a valid License file | Allowed only within the licensed scope and term |

The Free Features remain free even when an invalid, expired, or mismatched
commercial License is not loaded. A failed License does not convert an
unlicensed advanced feature into a production right.

## Standard commercial modules

The standard public checkout offers these rendering modules:

- `beauty`: the complete skin-beauty module beyond the Free Features, including
  supported local-detail effects such as bright eyes, teeth whitening, and dark
  circle reduction;
- `reshape`: face and facial-feature reshaping;
- `body`: body reshaping; and
- `makeup`: built-in makeup effects and presets.

The following technical capabilities are separate permissions and are **not
automatically included** merely because all four standard rendering modules
were purchased:

- `face_landmarks`;
- `body_pose`;
- `debug_outputs`; and
- `custom_makeup_assets`.

These capabilities may be used beyond evaluation only when they are expressly
listed in the License file or a separate written agreement.

## App and platform binding

A standard commercial License is issued for one App and may cover one or more
purchased platforms. Each selected platform is matched independently:

| Platform | Runtime identity |
|---|---|
| iOS | Bundle ID |
| Android | Application ID / package name |
| HarmonyOS | Bundle Name |

The runtime identity must exactly match an identity contained in the License
file. An identifier for one platform does not authorize another platform.
Debug, staging, TestFlight, extension, white-label, and additional product
identifiers are not covered unless they are expressly included.

Changing an App identifier normally requires correction, reissuance, upgrade,
or a separate License. Contact support before changing a production identifier.

## Scope and term

The current standard public offer is:

- one App;
- the purchased platforms;
- the purchased modules;
- a one-year term from issuance; and
- binary SDK use only.

Multi-App, white-label, redistributable SDK, source-code, private deployment,
custom model or asset, SLA, and other non-standard rights require a separate
enterprise agreement.

The signed License file is the SDK's technical source of truth for enabled
platforms, identifiers, modules, feature permissions, validity dates, and
supported SDK versions. The order and written terms remain the contractual
source of truth.

## License file handling

A License file is customer-specific authorization data. Keep it in a private
repository or protected build system and distribute it only inside the
authorized App when needed at runtime.

Do not:

- commit a License file to a public repository;
- place it in public documentation, issues, logs, sample code, or downloadable
  assets;
- share it with another organization or App;
- modify, forge, resell, or attempt to generate it; or
- publish decoded payloads, signatures, or internal validation details.

If a License file is exposed, visit
[https://uyalibeauty.com](https://uyalibeauty.com) and use the current contact
method shown on the website. Provide the License ID and order email, but do not
send signing private keys or payment credentials.

## Purchase, upgrade, and support

- Purchase or view current public terms at
  [https://uyalibeauty.com](https://uyalibeauty.com).
- Adding a platform or module during an active term is handled as an upgrade and
  produces a new License file.
- Adding another App or product identifier normally requires an enterprise
  quote or another License.
- Commercial support and update rights are limited to the purchased scope and
  term.

---

# 中文说明

本页说明 UyaliBeautySDK 的授权方式，但它本身不是 License 文件、报价单或独立商业授权。商业权利只有在完成购买或签署书面协议后产生，并受具体订单、签名 License 文件、[服务条款](https://uyalibeauty.com/terms)和 [SDK 许可协议](LICENSE.md)共同约束。

## 授权概览

| 模式 | 可用能力 | 正式上线与商业使用 |
|---|---|---|
| 免费模式 | `white`（美白）、`skin`（磨皮） | 无需 License 文件，可以免费商用 |
| 评估模式 | 每个引擎实例创建后，其他能力可体验 120 秒 | 仅限开发和购买前评估 |
| 商业模式 | 有效 License 文件明确列出的模块和功能 | 仅可在授权范围及有效期内商用 |

即使商业 License 无效、过期或与 App 标识不匹配，免费功能仍按免费模式使用；但商业 License 校验失败不会使高级功能获得正式商用权。

## 标准商业模块

官网标准购买页提供以下渲染模块：

- `beauty`：免费美白、磨皮之外的完整美颜模块，包括当前支持的亮眼、白牙、去黑眼圈等局部美颜能力；
- `reshape`：美型和五官调整；
- `body`：美体；
- `makeup`：SDK 内置美妆效果和预设。

以下技术能力属于独立权限，购买上述四个标准渲染模块并不代表自动获得：

- `face_landmarks`：人脸关键点输出；
- `body_pose`：人体关键点输出；
- `debug_outputs`：调试信息和调试点位输出；
- `custom_makeup_assets`：自定义美妆素材加载。

只有 License 文件或双方书面协议明确列出这些能力时，才可以超出评估范围使用。

## App 与平台绑定

标准商业 License 面向单个 App，可以购买一个或多个平台。各平台分别匹配：

| 平台 | 运行时身份 |
|---|---|
| iOS | Bundle ID |
| Android | Application ID / package name |
| HarmonyOS | Bundle Name |

运行时 App 标识必须与 License 文件中的标识完全一致。某个平台的 App 标识不能授权另一个平台。Debug、Staging、TestFlight、Extension、白标 App 和其他产品标识，只有被明确写入 License 时才属于授权范围。

生产 App 标识发生变化时，通常需要更正、重新签发、升级或另行购买 License，请在修改前联系支持。

## 标准范围与有效期

当前公开标准授权为：

- 单 App；
- 已购买的平台；
- 已购买的模块；
- 自签发之日起 1 年；
- 仅提供二进制 SDK 使用权。

多 App、白标、SDK 二次分发、源码、私有化部署、定制模型或素材、SLA 等非标准权利，需要另行签署企业协议。

SDK 在运行时以签名 License 文件记录的平台、App 标识、模块、功能权限、有效期和 SDK 版本范围为技术判断依据；合同权利仍以订单及书面条款为准。

## License 文件安全

License 文件是客户专属授权数据。请将其保存在私有仓库或受保护的构建系统中，并仅在运行确有需要时随已授权 App 分发。

不得：

- 将 License 文件提交到公开仓库；
- 将其放入公开文档、Issue、日志、示例代码或可下载资源；
- 与其他组织或 App 共用；
- 修改、伪造、转售或尝试自行生成；
- 公开解码后的 payload、签名或内部校验细节。

License 文件发生泄露时，请访问
[https://uyalibeauty.com](https://uyalibeauty.com)，通过网站当前提供的联系方式提交 License ID 和购买邮箱。请勿发送签名私钥或支付凭据。

## 购买、升级与支持

- 当前价格和购买入口：[https://uyalibeauty.com](https://uyalibeauty.com)。
- 有效期内增加平台或模块属于升级，升级后会生成新的 License 文件。
- 增加另一个 App 或产品标识通常需要企业报价或另行购买 License。
- 商业技术支持和版本更新仅限已购买范围及有效期。
