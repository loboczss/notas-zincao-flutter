enum CampoObrigatorio {
  nomeCliente,
  telefoneCliente,
  numeroNota,
  serieNota,
  dataCompra,
}

enum NotaFormStatus {
  idle,
  pickingImage,
  uploadingImage,
  analyzingReceipt,
  saving,
  success,
  duplicateFound,
  error,
  quotaExceeded,
}
