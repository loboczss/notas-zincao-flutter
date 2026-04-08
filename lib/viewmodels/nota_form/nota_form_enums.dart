enum CampoObrigatorio {
  nomeCliente,
  telefoneCliente,
  numeroNota,
  serieNota,
  chaveNfe,
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

enum CampoErroValidacao {
  nomeCliente,
  documentoCliente,
  telefoneCliente,
  numeroNota,
  serieNota,
  chaveNfe,
  dataCompra,
  desconto,
  produtos,
}
