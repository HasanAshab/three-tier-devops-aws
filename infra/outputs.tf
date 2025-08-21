output "url" {
  value = "http://${module.static_site_bucket.s3_bucket_bucket_domain_name}"
}