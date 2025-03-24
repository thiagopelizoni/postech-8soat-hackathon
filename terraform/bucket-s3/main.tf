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

resource "aws_iam_user" "s3_user" {
  name = "s3_user_videos_gazetapress"
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "s3_user_policy_videos_gazetapress"
  user = aws_iam_user.s3_user.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::videos.gazetapress.com"
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::videos.gazetapress.com/*"
      }
    ]
  })
}

resource "aws_iam_access_key" "s3_user_access_key" {
  user = aws_iam_user.s3_user.name
}

output "aws_access_key_id" {
  value = aws_iam_access_key.s3_user_access_key.id
}

output "aws_secret_access_key" {
  value     = aws_iam_access_key.s3_user_access_key.secret
  sensitive = true
}
