provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "videos_gazetapress" {
  bucket = "videos.gazetapress.com"
}

resource "aws_s3_bucket_public_access_block" "videos_gazetapress" {
  bucket = aws_s3_bucket.videos_gazetapress.bucket

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "videos_gazetapress_policy" {
  bucket = aws_s3_bucket.videos_gazetapress.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::videos.gazetapress.com/*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.videos_gazetapress]
}