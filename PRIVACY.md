# Privacy Policy - LocalLLM

**Last updated: March 2026**

## Overview

LocalLLM is designed with privacy as its core principle. The app runs AI models entirely on your device with no data transmission to external servers.

## Data Collection

**We do not collect any data.** Specifically:

- No personal information is collected
- No usage analytics or telemetry
- No crash reporting to external services
- No advertising identifiers
- No cookies or tracking

## Data Storage

All data is stored **locally on your device**:

- **Conversations**: Stored in a local SwiftData database on your device
- **Models**: Downloaded GGUF files stored in the app's Documents directory
- **Settings**: Stored in UserDefaults on your device

## Network Activity

The app makes network requests **only** in one scenario:

- **Model Downloads**: When you choose to download a model, the app fetches the GGUF file from HuggingFace (huggingface.co). No personal data is transmitted during this download.

During AI inference (chat), **no network activity occurs**. All processing is local.

## Third-Party Services

- **HuggingFace**: Used solely for hosting model files. Their privacy policy applies to the download requests. No user data is shared with HuggingFace.

## Data Deletion

- Delete individual conversations by swiping in the conversation list
- Delete downloaded models from the Models tab
- Uninstalling the app removes all data permanently

## Children's Privacy

The app does not knowingly collect information from children under 13.

## Changes

Any changes to this policy will be reflected in app updates with an updated date above.

## Contact

For privacy-related questions, contact **Ali Moustafa** at [mustafa30102001@gmail.com](mailto:mustafa30102001@gmail.com).
