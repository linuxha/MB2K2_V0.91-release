rem kernel
lwasm -p nosymbolcase -f -l os9 -o kernel\os9p1.bin kernel\os9p1.txt > kernel\os9p1.lis
lwasm -p nosymbolcase -f -l os9 -o kernel\os9p2.bin kernel\os9p2.txt > kernel\os9p2.lis
rem core
lwasm -p nosymbolcase -f -l os9 -o core\clock.bin core\clock.txt > core\clock.lis
lwasm -p nosymbolcase -f -l os9 -o core\sysgo.bin core\sysgo.txt > core\sysgo.lis
rem peripherals
lwasm -p nosymbolcase -f -l os9 -o periph\termio.bin periph\termio.txt > periph\termio.lis
lwasm -p nosymbolcase -f -l os9 -o periph\promdisk.bin periph\promdisk.txt > periph\promdisk.lis
lwasm -p nosymbolcase -f -l os9 -o periph\ramdisk.bin periph\ramdisk.txt > periph\ramdisk.lis
lwasm -p nosymbolcase -f -l os9 -o periph\fndisk.bin periph\fndisk.txt > periph\fndisk.lis
rem FLEXNet
lwasm -p nosymbolcase -f -l os9 -o FLEXNet\rmount.bin FLEXNet\rmount.txt > FLEXNet\rmount.lis
lwasm -p nosymbolcase -f -l os9 -o FLEXNet\rexit.bin FLEXNet\rexit.txt > FLEXNet\rexit.lis
lwasm -p nosymbolcase -f -l os9 -o FLEXNet\resync.bin FLEXNet\resync.txt > FLEXNet\resync.lis
lwasm -p nosymbolcase -f -l os9 -o FLEXNet\rdir.bin FLEXNet\rdir.txt > FLEXNet\rdir.lis
lwasm -p nosymbolcase -f -l os9 -o FLEXNet\rcd.bin FLEXNet\rcd.txt > FLEXNet\rcd.lis
rem cmds
lwasm -p nosymbolcase -f -l os9 -o mb2k2\blinky.bin mb2k2\blinky.txt > mb2k2\blinky.lis
rem data
lwasm -p nosymbolcase -f -l os9 -o mb2k2\gotoxy.bin mb2k2\gotoxy.txt > mb2k2\gotoxy.lis
rem create memory resident binary blob
copy /B kernel\os9p1.bin + kernel\os9p2.bin kernel\kernel.bin 
copy /B core\sysgo.bin + core\clock.bin + core\ioman.bin + core\scf.bin + core\rbf.bin core\core.bin 
copy /B periph\termio.bin + periph\promdisk.bin + periph\ramdisk.bin + periph\fndisk.bin periph\periph.bin 
copy /B mb2k2\blinky.bin cmds\cmds.bin
copy /B FLEXNet\resync.bin + FLEXNet\rexit.bin + FLEXNet\rmount.bin flexnet\flexnet.bin
copy /B kernel\kernel.bin + core\core.bin + periph\periph.bin + flexnet\flexnet.bin + mb2k2\gotoxy.bin os9.bin
copy os9.bin ..\mon09\os9.bin
