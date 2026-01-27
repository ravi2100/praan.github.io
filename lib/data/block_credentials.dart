class BlockCredential {
  final String block;
  final String userId;
  final String password;
  final String role;

  BlockCredential({
    required this.block,
    required this.userId,
    required this.password,
    required this.role,
  });
}

final List<BlockCredential> blockCredentials = [
  BlockCredential(
    block: 'Littipara',
    userId: 'pr-littipara-b-adm@panc.com',
    password: 'password',
    role: 'Block Admin',
  ),
  BlockCredential(
    block: 'Pakuria',
    userId: 'pr-pakuria-b-adm@panc.com',
    password: 'password',
    role: 'Block Admin',
  ),
  BlockCredential(
    block: 'Amrapara',
    userId: 'pr-amrapara-b-adm@panc.com',
    password: 'password',
    role: 'Block Admin',
  ),
  BlockCredential(
    block: 'Pakur',
    userId: 'pr-pakur-adm@panc.com',
    password: 'password',
    role: 'Block Admin',
  ),
  BlockCredential(
    block: 'Mahespur',
    userId: 'pr-mahespur-adm@panc.com',
    password: 'password',
    role: 'Block Admin',
  ),
  BlockCredential(
    block: 'Hiranpur',
    userId: 'pr-hiranpur-adm@panc.com',
    password: 'password',
    role: 'Block Admin',
  ),
];
