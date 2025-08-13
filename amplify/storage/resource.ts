import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
  name: 'coletaneaDigitalStorage',
  access: (allow: any) => ({
    'materiais/louvor/*': [
      allow.guest.to(['read', 'write', 'delete']),
    ]
  })
});
