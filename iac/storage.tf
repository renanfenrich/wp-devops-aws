resource "aws_s3_bucket" "assets" {
  bucket        = "${local.prefix}-assets"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "assets" {
  bucket = aws_s3_bucket.assets.id
  acl    = "public-read"
}
