# Cursor Reset

A tool for resetting the trial period of the Cursor Editor.

[![GitHub license](https://img.shields.io/github/license/isboyjc/cursor-reset)](https://github.com/isboyjc/cursor-reset/blob/master/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/isboyjc/cursor-reset)](https://github.com/isboyjc/cursor-reset/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/isboyjc/cursor-reset)](https://github.com/isboyjc/cursor-reset/issues)
[![GitHub forks](https://img.shields.io/github/forks/isboyjc/cursor-reset)](https://github.com/isboyjc/cursor-reset/network)

[简体中文](./README_zh-CN.md) | English

## Features

- 🚀 One-click reset of Cursor Editor trial period
- 💪 Cross-platform support (Windows, macOS, Linux)
- 🔧 Simple and easy to use
- 🎯 No configuration required

## Usage

### Method 1: Direct Script Execution

#### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/isboyjc/cursor-reset/main/scripts/reset.ps1 | iex
```

**jsdelivr cdn **
```powershell
irm https://cdn.jsdelivr.net/gh/isboyjc/cursor-reset@main/scripts/reset.ps1 | iex
```


#### macOS/Linux

```bash
curl -fsSL https://raw.githubusercontent.com/isboyjc/cursor-reset/main/scripts/reset.sh | sh
```

**jsdelivr cdn **
```bash
curl -fsSL https://cdn.jsdelivr.net/gh/isboyjc/cursor-reset@main/scripts/reset.sh | sh
```

### Method 2: Download Executable

1. Go to our [releases page](https://github.com/isboyjc/cursor-reset/releases)
2. Download the version for your operating system:
   - Windows: `cursor-reset-win.exe`
   - macOS: `cursor-reset-macos`
   - Linux: `cursor-reset-linux`
3. Run the executable:
   - Windows/macOS: Double click to run
   - Linux: Open terminal and run:
     ```bash
     chmod +x cursor-reset-linux  # Make it executable (first time only)
     ./cursor-reset-linux         # Run the tool
     ```

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/isboyjc/cursor-reset.git
```

2. Install dependencies:
```bash
cd cursor-reset
npm install
```

3. Build executables:
```bash
npm run build:all
```

The built executables will be available in the `dist` directory.

## How It Works

The tool works by clearing the Cursor Editor's local storage data that tracks the trial period. This allows you to start a fresh trial period.

## Supported Platforms

- Windows
- macOS
- Linux

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This tool is for educational purposes only. Please support the developers by purchasing a license if you find the Cursor Editor useful.
