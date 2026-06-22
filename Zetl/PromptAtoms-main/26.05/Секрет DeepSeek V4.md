---
tags:
- 2026/May
- infrastructure/vram_optimization
- engineering/models/transformer_architecture
- engineering/models/context_compression
author:
- Vladimir Ivanov
---
!

-----
## как технология MLA сокращает KV Cache в 32 раза для работы с мега-контекстом
-----
DeepSeek оптимизировали потребление VRAM в модели V4, сумев вместить 8000 векторов глобального контекста (на 1 миллион токенов) всего в 9,62 ГБ. 

Этого удалось достичь за счет применения архитектуры MLA (Multi-head Latent Attention), которая сжимает размерность векторов с 7168 до 512 и использует 128 головок внимания, что в конечном итоге уменьшает размер KV Cache в 32 раза.

---
## Zero-links
---
- 
- 
- 
- 
- 
- 

---
## Links
---
- [Source](https://t.me/turboproject/4247)