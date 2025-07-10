# Connecting to your Hendrix drive on Windows

This guide will allow you to connect to your Hendrix files from windows using a network drive.
The guide is KU-Computer compatible. 

1. Download & Install Windows File System Proxy: https://github.com/winfsp/winfsp/releases
2. Download & Install SSHFS for Windows: https://github.com/winfsp/sshfs-win/releases
3. Check that C:/Users/<kuid>/.ssh/config is correct and that you can connect to hendrixgate using ssh.
4. Open "This PC"
5. Right click "This PC" (left sidebar) -> Map Network Drive
6. Choose a drive letter and choose as path \\sshfs\<kuid>@hendrixgate
7. Type in your credentials
8. You should now be able to access the network drive as X:

If you have problems following steps 4-7, there is a gif on https://github.com/winfsp/sshfs-win?tab=readme-ov-file#windows-explorer
