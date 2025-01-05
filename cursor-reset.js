#!/usr/bin/env node

/**
 * Cursor Trial Reset Tool
 * 
 * 这是一个 Cursor 编辑器试用重置工具
 * 该脚本通过重置 Cursor 配置文件中的设备 ID 来生成新的随机设备 ID，从而重置试用期。
 * 支持 Windows、macOS 和 Linux 系统。
 * 
 * 主要功能：
 * - 自动检测并关闭运行中的 Cursor 进程
 * - 备份现有配置文件
 * - 生成新的随机设备 ID
 * - 统计重置历史记录
 * 
 * 仓库地址: https://github.com/isboyjc/cursor-reset
 * 作者: @isboyjc
 * 创建时间: 29/Dec/2024
 */

const fs = require('fs').promises;
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { execSync } = require('child_process');
const readline = require('readline');

/**
 * 等待用户按键
 * 在 Windows 系统下运行时，程序结束前等待用户按键
 * 这样可以防止在双击运行时窗口立即关闭
 * 
 * @returns {Promise<void>} 返回一个 Promise，在用户按键后解决
 */
function waitForKeypress() {
  // 在 Windows 系统下（无论 32 位还是 64 位）且不是在终端中运行时等待
  if (process.platform === 'win32' && !process.env.TERM) {
    console.log('\n按任意键退出...');
    return new Promise(resolve => {
      const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
      });

      const cleanup = () => {
        rl.close();
        resolve();
      };

      // 监听按键事件
      process.stdin.setRawMode(true);
      process.stdin.resume();
      process.stdin.once('data', () => {
        process.stdin.setRawMode(false);
        cleanup();
      });

      // 如果用户关闭窗口，也要清理
      rl.once('close', cleanup);
    });
  }
  return Promise.resolve();
}

/**
 * 用户确认提示
 * 显示一个 yes/no 提示，等待用户输入
 * 
 * @param {string} question 要显示给用户的问题
 * @returns {Promise<boolean>} 如果用户输入 'y' 或 'Y' 返回 true，否则返回 false
 */
async function confirm(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(question + ' (y/N): ', answer => {
      rl.close();
      resolve(answer.toLowerCase() === 'y');
    });
  });
}

/**
 * 获取 Windows 系统下运行的 Cursor 进程名
 * 使用 wmic 命令获取详细的进程信息，并过滤出 Cursor 相关进程
 * 
 * @returns {Promise<string|null>} 返回找到的第一个 Cursor 进程名，如果没找到则返回 null
 */
async function getWindowsCursorProcessName() {
  try {
    // 使用 wmic 命令获取更准确的进程信息
    const result = execSync('wmic process get name,processid /format:csv', { encoding: 'utf-8' });
    const lines = result.trim().split('\n').map(line => line.trim());
    
    // 移除表头
    if (lines.length > 1) {
      lines.shift();
    }
    
    // 获取当前进程的 PID
    const currentPid = process.pid;
    
    // 过滤掉空行、不相关的进程和当前进程
    const processes = lines
      .filter(line => {
        const [node, name, pid] = line.split(',').map(item => item.trim().toLowerCase());
        // 排除当前进程和其他非 Cursor 进程
        return name && 
               name.includes('cursor') && 
               !name.includes('cursor-reset') && // 排除我们的脚本
               parseInt(pid) !== currentPid; // 排除当前进程
      })
      .map(line => line.split(',')[1].trim());

    if (processes.length > 0) {
      console.log('找到的 Cursor 进程：', processes);
      return processes[0];
    }
    return null;
  } catch (error) {
    console.log('获取进程名时出错：', error.message);
    return null;
  }
}

/**
 * 检查 Cursor 是否正在运行
 * 根据不同操作系统使用不同的命令检查进程
 * - Windows: 使用 wmic 命令
 * - macOS: 使用 pgrep 命令
 * - Linux: 使用 pgrep 命令
 * 
 * @returns {boolean} 如果 Cursor 正在运行返回 true，否则返回 false
 */
function isCursorRunning() {
  try {
    const platform = process.platform;
    let result = '';
    
    if (platform === 'win32') {
      // Windows 下使用 wmic 命令
      result = execSync('wmic process get name,processid /format:csv', { encoding: 'utf-8' });
      const currentPid = process.pid;
      
      const processes = result.toLowerCase()
        .split('\n')
        .map(line => line.trim())
        .filter(line => {
          if (!line || line.startsWith('node,name,processid')) return false;
          const [node, name, pid] = line.split(',').map(item => item.trim());
          // 排除我们的脚本和当前进程
          return name && 
                 name.includes('cursor') && 
                 !name.includes('cursor-reset') &&
                 parseInt(pid) !== currentPid;
        });
      
      console.log('检测到的 Cursor 进程：', processes);
      return processes.length > 0;
    } else if (platform === 'darwin') {
      result = execSync('pgrep -x "Cursor" || pgrep -x "Cursor Helper"', { encoding: 'utf-8' });
      return result.length > 0;
    } else if (platform === 'linux') {
      result = execSync('pgrep -x "cursor" || pgrep -x "Cursor"', { encoding: 'utf-8' });
      return result.length > 0;
    } else {
      throw new Error(`不支持的操作系统: ${platform}`);
    }
  } catch (error) {
    if (error.status === 1) {
      // pgrep 在没找到进程时返回状态码 1
      return false;
    }
    console.log('检查进程时出错：', error.message);
    return false;
  }
}

/**
 * 强制关闭 Cursor 进程
 * 根据不同操作系统使用相应的命令关闭进程：
 * - Windows: taskkill 命令
 * - macOS: pkill 命令
 * - Linux: pkill 命令
 * 
 * @returns {Promise<boolean>} 成功关闭返回 true，失败返回 false
 */
async function killCursorProcess() {
  try {
    const platform = process.platform;
    let command = '';
    
    switch (platform) {
      case 'win32': {
        const processName = await getWindowsCursorProcessName();
        if (!processName) {
          console.log('未找到需要关闭的 Cursor 进程');
          return true; // 如果没有找到进程，认为已经关闭
        }
        command = `taskkill /F /IM "${processName}" /T`;
        break;
      }
      case 'darwin':
        command = 'pkill -9 "Cursor"';
        break;
      case 'linux':
        command = 'pkill -9 "cursor"';
        break;
      default:
        throw new Error(`不支持的操作系统: ${platform}`);
    }

    console.log('执行关闭命令：', command);
    execSync(command);
    
    // 等待进程完全关闭
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    // 验证进程是否真的关闭了
    if (isCursorRunning()) {
      throw new Error('进程仍在运行');
    }
    
    return true;
  } catch (error) {
    console.error('关闭 Cursor 进程时出错：', error.message);
    return false;
  }
}

/**
 * 格式化时间戳
 * 将日期对象转换为格式化的时间字符串
 * 格式：yyyyMMddHHmmssSSS
 * 
 * @param {Date} date 要格式化的日期对象
 * @returns {string} 格式化后的时间字符串
 */
function formatTimestamp(date) {
  const pad = (num, len = 2) => String(num).padStart(len, '0');
  
  const year = date.getFullYear();
  const month = pad(date.getMonth() + 1);
  const day = pad(date.getDate());
  const hours = pad(date.getHours());
  const minutes = pad(date.getMinutes());
  const seconds = pad(date.getSeconds());
  const milliseconds = pad(date.getMilliseconds(), 3);

  return `${year}${month}${day}${hours}${minutes}${seconds}${milliseconds}`;
}

/**
 * 备份配置文件
 * 创建配置文件的时间戳备份，文件名格式为：原文件名.时间戳.bak
 * 
 * @param {string} filePath 需要备份的文件路径
 * @returns {Promise<string>} 备份文件的完整路径
 * @throws {Error} 备份失败时抛出错误
 */
async function backupFile(filePath) {
  try {
    const timestamp = formatTimestamp(new Date());
    const backupPath = `${filePath}.${timestamp}.bak`;
    await fs.copyFile(filePath, backupPath);
    return backupPath;
  } catch (error) {
    throw new Error(`备份文件失败: ${error.message}`);
  }
}

/**
 * 检查 Cursor 是否已安装
 * 根据不同操作系统检查 Cursor 的默认安装位置
 * 
 * @returns {Promise<boolean>} Cursor 已安装返回 true，否则返回 false
 * @throws {Error} 不支持的操作系统时抛出错误
 */
async function isCursorInstalled() {
  const platform = process.platform;
  let cursorPath = '';

  switch (platform) {
    case 'win32':
      cursorPath = path.join(process.env.LOCALAPPDATA, 'Programs', 'Cursor', 'Cursor.exe');
      break;
    case 'darwin':
      cursorPath = '/Applications/Cursor.app';
      break;
    case 'linux':
      // Linux 可能有多个安装位置，检查最常见的几个
      const linuxPaths = [
        '/usr/share/cursor',
        '/opt/cursor',
        path.join(os.homedir(), '.local/share/cursor')
      ];
      for (const p of linuxPaths) {
        try {
          await fs.access(p);
          cursorPath = p;
          break;
        } catch {}
      }
      break;
    default:
      throw new Error(`不支持的操作系统: ${platform}`);
  }

  try {
    await fs.access(cursorPath);
    return true;
  } catch {
    return false;
  }
}

/**
 * 获取 Cursor 存储文件路径
 * 根据不同操作系统返回配置文件的标准位置：
 * - Windows: %APPDATA%/Cursor/User/globalStorage/storage.json
 * - macOS: ~/Library/Application Support/Cursor/User/globalStorage/storage.json
 * - Linux: ~/.config/Cursor/User/globalStorage/storage.json
 * 
 * @returns {string} 配置文件的完整路径
 * @throws {Error} 不支持的操作系统时抛出错误
 */
function getStorageFile() {
  const platform = process.platform;
  const homedir = os.homedir();

  switch (platform) {
    case 'win32': // Windows
      return path.join(process.env.APPDATA, 'Cursor', 'User', 'globalStorage', 'storage.json');
    case 'darwin': // macOS
      return path.join(homedir, 'Library', 'Application Support', 'Cursor', 'User', 'globalStorage', 'storage.json');
    case 'linux': // Linux
      return path.join(homedir, '.config', 'Cursor', 'User', 'globalStorage', 'storage.json');
    default:
      throw new Error(`不支持的操作系统: ${platform}`);
  }
}

/**
 * 生成新的随机设备标识
 * 生成三种不同的设备 ID：
 * - machineId: 32 字节的随机十六进制字符串
 * - macMachineId: 32 字节的随机十六进制字符串
 * - devDeviceId: UUID v4 格式的随机字符串
 * 
 * @returns {object} 包含新生成的三个设备 ID 的对象
 */
function generateDeviceIds() {
  return {
    machineId: crypto.randomBytes(32).toString('hex'),
    macMachineId: crypto.randomBytes(32).toString('hex'),
    devDeviceId: crypto.randomUUID()
  };
}

/**
 * 获取配置文件的所有备份记录
 * 搜索指定目录下所有以 .bak 结尾的备份文件
 * 解析文件名中的时间戳并按时间倒序排列
 * 
 * @param {string} configPath 配置文件路径
 * @returns {Promise<Array<{name: string, time: Date}>>} 备份文件信息数组
 */
async function getBackupFiles(configPath) {
  try {
    const dir = path.dirname(configPath);
    const base = path.basename(configPath);
    const files = await fs.readdir(dir);
    
    // 找到所有备份文件
    return files
      .filter(file => file.startsWith(base) && file.includes('.bak'))
      .map(file => {
        // 从文件名中提取时间戳
        const timestamp = file.split('.')[1];
        // 解析时间戳 (yyyyMMddHHmmssSSS)
        const year = timestamp.slice(0, 4);
        const month = timestamp.slice(4, 6);
        const day = timestamp.slice(6, 8);
        const hours = timestamp.slice(8, 10);
        const minutes = timestamp.slice(10, 12);
        const seconds = timestamp.slice(12, 14);
        const milliseconds = timestamp.slice(14);
        
        const time = new Date(
          parseInt(year),
          parseInt(month) - 1,
          parseInt(day),
          parseInt(hours),
          parseInt(minutes),
          parseInt(seconds),
          parseInt(milliseconds)
        );
        
        return {
          name: file,
          time: time
        };
      })
      .sort((a, b) => b.time - a.time); // 按时间倒序排列
  } catch (error) {
    console.error('获取备份文件列表时出错：', error);
    return [];
  }
}

/**
 * 重置 Cursor 的设备标识
 * 执行完整的重置流程：
 * 1. 检查 Cursor 安装状态
 * 2. 检查并关闭运行中的 Cursor
 * 3. 准备配置目录
 * 4. 备份现有配置
 * 5. 生成新的设备 ID
 * 6. 保存新配置
 * 7. 显示重置统计信息
 */
async function resetCursorId() {
  try {
    console.log('🔍 正在检查 Cursor 编辑器...');
    if (!await isCursorInstalled()) {
      console.error('❌ 未检测到 Cursor 编辑器，请先安装 Cursor！');
      console.error('下载地址：https://www.cursor.com/downloads');
      return;
    }
    console.log('✅ Cursor 编辑器已安装\n');

    console.log('🔍 检查 Cursor 是否在运行...');
    if (isCursorRunning()) {
      const shouldKill = await confirm('检测到 Cursor 正在运行，是否自动关闭？');
      if (shouldKill) {
        console.log('正在关闭 Cursor...');
        if (await killCursorProcess()) {
          console.log('✅ Cursor 已成功关闭\n');
        } else {
          console.error('❌ 无法自动关闭 Cursor，请手动关闭后重试！');
          return;
        }
      } else {
        console.error('❌ 请先关闭 Cursor 编辑器后再运行此工具！');
        return;
      }
    } else {
      console.log('✅ Cursor 编辑器已关闭\n');
    }

    console.log('📂 正在准备配置文件...');
    const storageFile = getStorageFile();
    await fs.mkdir(path.dirname(storageFile), { recursive: true });
    console.log('✅ 配置目录创建成功\n');

    console.log('💾 正在备份原配置...');
    const backupPath = await backupFile(storageFile);
    console.log(`✅ 配置备份完成，备份文件路径：${path.basename(backupPath)}\n`);

    console.log('🔄 正在读取配置文件...');
    let data = {};
    try {
      const fileContent = await fs.readFile(storageFile, 'utf-8');
      data = JSON.parse(fileContent);
      console.log('✅ 配置文件读取成功\n');
    } catch (error) {
      console.log('ℹ️ 未找到现有配置，将创建新配置\n');
    }

    console.log('🎲 正在生成新的设备 ID...');
    const newIds = generateDeviceIds();
    data['telemetry.machineId'] = newIds.machineId;
    data['telemetry.macMachineId'] = newIds.macMachineId;
    data['telemetry.devDeviceId'] = newIds.devDeviceId;
    console.log('✅ 新设备 ID 生成成功\n');

    console.log('💾 正在保存新配置...');
    await fs.writeFile(storageFile, JSON.stringify(data, null, 2), 'utf-8');
    console.log('✅ 新配置保存成功\n');

    console.log('🎉 设备 ID 重置成功！新的设备 ID 为：\n');
    console.log(JSON.stringify(newIds, null, 2));
    console.log(`\n📝 配置文件路径：${storageFile}`);

    // 获取所有备份文件
    const backupFiles = await getBackupFiles(storageFile);
    const resetCount = backupFiles.length;

    console.log(`\n📊 重置统计：`);
    console.log(`   总计重置次数：${resetCount} 次`);
    if (resetCount > 0) {
      console.log('\n📜 历史备份文件：');
      backupFiles.forEach((file, index) => {
        console.log(`   ${index + 1}. ${file.name}`);
      });
    }
    console.log('\n✨ 现在可以启动 Cursor 编辑器了');
  } catch (error) {
    console.error('\n❌ 重置设备 ID 时出错：', error);
  }
}

/**
 * 主程序入口
 * 执行重置流程并处理异常
 * 确保在程序结束前等待用户确认（Windows）
 */
async function main() {
  let exitCode = 0;
  try {
    await resetCursorId();
  } catch (error) {
    console.error('\n❌ 程序执行出错：', error);
    exitCode = 1;
  } finally {
    // 无论成功还是失败，都等待用户按键后再退出
    await waitForKeypress();
    process.exit(exitCode);
  }
}

if (require.main === module) {
  main().catch(error => {
    console.error('程序异常退出：', error);
    process.exit(1);
  });
}
