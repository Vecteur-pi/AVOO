enum VerificationMethod {
  email,
  phone,
}

String verificationMethodLabel(VerificationMethod method) {
  switch (method) {
    case VerificationMethod.email:
      return 'E-mail';
    case VerificationMethod.phone:
      return 'Téléphone';
  }
}
