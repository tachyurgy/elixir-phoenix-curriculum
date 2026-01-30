# Appendix A1: Installing Elixir and Erlang

This guide covers installing Elixir and Erlang/OTP on various operating systems. Elixir runs on the Erlang VM (BEAM), so you need both installed.

## Table of Contents

1. [Version Requirements](#version-requirements)
2. [Using asdf (Recommended)](#using-asdf-recommended)
3. [macOS Installation](#macos-installation)
4. [Linux Installation](#linux-installation)
5. [Windows Installation](#windows-installation)
6. [Verifying Your Installation](#verifying-your-installation)
7. [Troubleshooting](#troubleshooting)

---

## Version Requirements

### Recommended Versions

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Erlang/OTP | 24.0 | 26.x or newer |
| Elixir | 1.14 | 1.16.x or newer |

### Compatibility Notes

- Elixir versions are tied to specific Erlang/OTP versions
- Check the [Elixir compatibility chart](https://hexdocs.pm/elixir/compatibility-and-deprecations.html)
- Phoenix 1.7+ requires Elixir 1.14+

---

## Using asdf (Recommended)

asdf is a version manager that handles multiple runtime versions. It's the recommended approach for Elixir development as it allows you to:

- Manage multiple Elixir and Erlang versions
- Switch versions per project using `.tool-versions` files
- Keep consistent versions across team members

### Installing asdf

#### macOS

```bash
# Using Homebrew
brew install asdf

# Add to shell (for zsh)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc

# For bash
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.bash_profile
```

#### Linux (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y curl git

# Clone asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# Add to shell (for bash)
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

# For zsh
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
```

### Installing Erlang and Elixir Plugins

```bash
# Add the Erlang plugin
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git

# Add the Elixir plugin
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
```

### Installing Erlang with asdf

Erlang requires build dependencies. Install them first:

#### macOS Build Dependencies

```bash
brew install autoconf openssl wxwidgets libxslt fop
export KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl)"
```

#### Ubuntu/Debian Build Dependencies

```bash
sudo apt-get install -y build-essential autoconf m4 libncurses5-dev \
  libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev \
  libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
  libxml2-utils libncurses-dev openjdk-11-jdk
```

#### Building Erlang

```bash
# List available Erlang versions
asdf list-all erlang

# Install specific version (this takes 10-20 minutes)
asdf install erlang 26.2.1

# Set global default
asdf global erlang 26.2.1
```

### Installing Elixir with asdf

```bash
# List available Elixir versions
asdf list-all elixir

# Install specific version (include OTP version for compatibility)
asdf install elixir 1.16.1-otp-26

# Set global default
asdf global elixir 1.16.1-otp-26
```

### Project-Specific Versions

Create a `.tool-versions` file in your project root:

```bash
# In your project directory
echo "erlang 26.2.1" >> .tool-versions
echo "elixir 1.16.1-otp-26" >> .tool-versions

# Install versions if not present
asdf install
```

---

## macOS Installation

### Using Homebrew (Quick Start)

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Erlang and Elixir
brew install erlang elixir

# Verify installation
elixir --version
```

### Homebrew Advantages and Limitations

**Advantages:**
- Simple one-command installation
- Automatic dependency management
- Easy updates with `brew upgrade`

**Limitations:**
- Only one version at a time
- Updates may break projects expecting older versions
- Less control over build options

---

## Linux Installation

### Ubuntu/Debian

#### Using Package Manager (Quick but Older Versions)

```bash
# Add Erlang Solutions repository
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update

# Install Erlang and Elixir
sudo apt-get install -y esl-erlang elixir
```

#### Using Official Repositories (Newest Versions)

```bash
# Install required dependencies
sudo apt-get install -y gnupg2

# Add Erlang Solutions GPG key
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -

# Add repository
echo "deb https://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | \
  sudo tee /etc/apt/sources.list.d/erlang-solutions.list

sudo apt-get update
sudo apt-get install -y esl-erlang elixir
```

### Fedora/RHEL/CentOS

```bash
# Enable EPEL repository (for RHEL/CentOS)
sudo dnf install -y epel-release

# Install Erlang and Elixir
sudo dnf install -y erlang elixir
```

### Arch Linux

```bash
sudo pacman -S erlang elixir
```

---

## Windows Installation

### Using the Official Installer (Recommended)

1. **Install Erlang/OTP**
   - Download from [Erlang Downloads](https://www.erlang.org/downloads)
   - Run the installer (e.g., `otp_win64_26.2.1.exe`)
   - Accept default installation path
   - Add to PATH when prompted

2. **Install Elixir**
   - Download from [Elixir Downloads](https://elixir-lang.org/install.html#windows)
   - Run the installer
   - Ensure "Add to PATH" is checked

3. **Verify in PowerShell or Command Prompt**
   ```powershell
   erl -version
   elixir --version
   ```

### Using Chocolatey

```powershell
# Install Chocolatey (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Erlang and Elixir
choco install erlang elixir
```

### Using Scoop

```powershell
# Install Scoop
irm get.scoop.sh | iex

# Install Erlang and Elixir
scoop install erlang elixir
```

### Windows Subsystem for Linux (WSL)

For the best development experience on Windows, consider using WSL2:

```powershell
# Enable WSL (run as Administrator)
wsl --install

# After restart, install Ubuntu from Microsoft Store
# Then follow Linux installation instructions
```

---

## Verifying Your Installation

### Check Versions

```bash
# Check Erlang version
erl -version
# or
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

# Check Elixir version
elixir --version
```

Expected output:

```
Erlang/OTP 26 [erts-14.2.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Elixir 1.16.1 (compiled with Erlang/OTP 26)
```

### Test IEx (Interactive Elixir)

```bash
iex
```

In IEx:

```elixir
iex> IO.puts("Hello, Elixir!")
Hello, Elixir!
:ok

iex> 1 + 1
2

iex> System.version()
"1.16.1"
```

Exit with `Ctrl+C` twice or type `:q`.

### Test Mix

```bash
# Check Mix version
mix --version

# Create a test project
mix new hello_world
cd hello_world
mix test
```

### Test Hex Package Manager

```bash
# Install Hex (usually included)
mix local.hex

# Check Hex version
mix hex.info
```

---

## Troubleshooting

### Common Issues

#### "erl: command not found"

Erlang is not in your PATH. Solutions:

```bash
# macOS (Homebrew)
export PATH="/usr/local/opt/erlang/bin:$PATH"

# Linux - find Erlang installation
which erl
# Add to PATH in ~/.bashrc or ~/.zshrc
```

#### "elixir: command not found"

```bash
# Check if Elixir is installed
ls /usr/local/bin/elixir

# Add to PATH
export PATH="/usr/local/bin:$PATH"
```

#### Erlang Build Fails (asdf)

Common causes and solutions:

```bash
# Missing OpenSSL
export KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl)"

# Missing wxWidgets (for observer)
brew install wxwidgets

# Skip wxWidgets if not needed
export KERL_CONFIGURE_OPTIONS="--without-wx"
```

#### Version Mismatch Errors

```
** (Mix) You're trying to run :my_app on Elixir v1.14.0 but it requires v1.16.0
```

Solutions:
- Update Elixir: `asdf install elixir 1.16.1-otp-26 && asdf global elixir 1.16.1-otp-26`
- Check project `.tool-versions` file
- Run `asdf install` in the project directory

#### Hex Certificate Errors

```bash
# Update certificates
mix local.hex --force
mix local.rebar --force

# On some systems
export HEX_CACERTS_PATH=/etc/ssl/certs/ca-certificates.crt
```

### Getting Help

- [Elixir Forum](https://elixirforum.com/) - Active community
- [Elixir Discord](https://discord.gg/elixir) - Real-time help
- [Stack Overflow](https://stackoverflow.com/questions/tagged/elixir) - Q&A
- [GitHub Issues](https://github.com/elixir-lang/elixir/issues) - Bug reports

---

## Next Steps

After installation:

1. Set up your editor (see [Appendix A2: Editor Setup](a2_editor_setup.md))
2. Learn IEx tips (see [Appendix A3: IEx Tips](a3_iex_tips.md))
3. Start with the curriculum's first module

---

*Last updated: January 2025*
