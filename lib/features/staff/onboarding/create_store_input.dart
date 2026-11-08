class CreateStoreInput {
  const CreateStoreInput({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.phone,
    this.email,
    this.whatsappNumber,
    this.description,
    this.gstNumber,
    this.drugLicenseNumber,
    this.slug,
  });

  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? phone;
  final String? email;
  final String? whatsappNumber;
  final String? description;
  final String? gstNumber;
  final String? drugLicenseNumber;
  final String? slug;
}
