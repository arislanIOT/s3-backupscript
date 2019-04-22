#!/bin/bash

### setting date for backup configuration ###

NOWDATE=$(date +%Y-%m-%d)
LASTDATE=$(date +%Y-%m-%d --date="30 days ago")

### setting backup directory variables ###

WEBDIR=/home
SRCDIR='/backup'
DESTDIR='pat/to/s3folder'
BUCKET='bucketname'

### Database access details ###

HOST='localhost'
PORT='3306'
USER=root
PASS=''

### configuration details ended ###

## make the temp directory if it does not exist and enter into it.

mkdir -p /backup
cd /backup

### command specifies to dump each Database to its own sql file

for DB in $(mysql -h$HOST -P$PORT -u$USER -p$PASS -BNe  'show databases'| grep -Ev 'mysql|information_schema|performance_schema')
do
mysqldump -h$HOST -P$PORT -u$USER -p$PASS --quote-names --create-options --force $DB > $SRCDIR/$DB.sql
done

### Tar the databases to our src directory ###
cd $SRCDIR
tar -czPf $NOWDATE-backup-sql.tar.gz  *.sql

### Tar website files to our src directory ###

tar -czPf $NOWDATE-backup.tar.gz $WEBDIR

### Uploading to S3 Bucket ###

### Database ###
aws s3 cp  $SRCDIR/$NOWDATE-backup-sql.tar.gz s3://$BUCKET/$DESTDIR
### Website home directory ###
aws s3 cp  $SRCDIR/$NOWDATE-backup.tar.gz s3://$BUCKET/$DESTDIR

## Deleting the old backup more than 30 days

# deleting website backup
## aws  

aws s3 rm --recursive s3://$BUCKET/$DESTDIR/$LASTDATE-backup.tar.gz

#deleting sql backup
aws s3 rm --recursive s3://$BUCKET/$DESTDIR/$LASTDATE-backup-sql.tar.gz

## Remove files from source directory

cd $SRCDIR
rm -f $SRCDIR/*
