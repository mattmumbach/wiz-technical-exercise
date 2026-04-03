# backup.tf
# Intentional misconfiguration: public-readable S3 bucket for MongoDB backups

resource "aws_s3_bucket" "mongodb_backup" {
  bucket        = "wiz-exercise-backup-864899846082"
  force_destroy = true

  tags = {
    Name        = "wiz-mongodb-backup"
    Environment = "wiz-exercise"
  }
}

# Must disable block public access before a public bucket policy will apply
resource "aws_s3_bucket_public_access_block" "mongodb_backup" {
  bucket = aws_s3_bucket.mongodb_backup.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Intentional weakness: allows anyone to read objects and list the bucket
resource "aws_s3_bucket_policy" "mongodb_backup_public" {
  bucket     = aws_s3_bucket.mongodb_backup.id
  depends_on = [aws_s3_bucket_public_access_block.mongodb_backup]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.mongodb_backup.arn,
        "${aws_s3_bucket.mongodb_backup.arn}/*"
      ]
    }]
  })
}

output "mongodb_backup_bucket_url" {
  value       = "https://${aws_s3_bucket.mongodb_backup.bucket}.s3.amazonaws.com"
  description = "Public URL of the MongoDB backup bucket"
}
