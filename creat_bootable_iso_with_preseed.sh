# script to create an ISO image with automatic installation
# capability from debian-6.0.5-CD-1.iso

if [ $# -ne 3 ]
then
 echo "Usage: $0 input.iso output.iso your-preseed-file"
 exit 1
fi
iso=$1
output=$2
preseed=$3
lpdir=__loopdir__
cddir=__cd__
irdir=__irmod__

# Copy image
mkdir $lpdir
mount -o loop $iso $lpdir
rm -rf $cddir
mkdir $cddir
rsync -a -H --exclude=TRANS.TBL $lpdir/ $cddir
umount $lpdir

# Hack initrd
mkdir $irdir
cd $irdir
gzip -d < ../$cddir/install.386/initrd.gz | \
 cpio --extract --verbose --make-directories --no-absolute-filenames
cp ../$preseed preseed.cfg
find . | cpio -H newc --create --verbose | \
 gzip -9 > ../$cddir/install.386/initrd.gz
cd ../
rm -rf $irdir

# Modify default option
cd $cddir/isolinux
sed 's/timeout 0/timeout 5/' isolinux.cfg > tmp
mv tmp isolinux.cfg
sed 's/vga=788/console=ttyS0,9600n8/' txt.cfg > tmp
mv tmp txt.cfg
cd ../../
# Fix checksum
cd $cddir
md5sum `find -follow -type f` > md5sum.txt
cd ..

# Create bootable CD
mkisofs -o $output -r -J -no-emul-boot -boot-load-size 4 \
 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat ./$cddir

# Cleaning up
rm -rf $lpdir
rm -rf $cddir

echo "Created $output!"

