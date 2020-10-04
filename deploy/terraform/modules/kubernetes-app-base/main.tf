resource "null_resource" "cluster_blocker" {
  provisioner "local-exec" {
    command = "echo ${var.cluster_blocker}"
  }
}

resource "kubernetes_namespace" "watchn" {
  depends_on = [null_resource.cluster_blocker]
  
  metadata {
    name = "watchn"

    labels = {
      //"appmesh.k8s.aws/sidecarInjectorWebhook" = "enabled"
      //"mesh" = aws_appmesh_mesh.default.name
    }
  }
}