# AWS-novatrix-mov25

**Namn:** Adrian Ahlborg
**Kurs:** Amazon Web Services (Moln- och virtualiseringsspecialist, Campus Mölndal)
**Företag:** Novatrix AB – flytt av webbplatsen till AWS

En mapp per kursvecka. Allt bygger vidare på samma miljö (EC2 → nätverk, databas, lagring, skalbarhet, monitorering → WordPress).

| Vecka | Tema | Mapp |
|---|---|---|
| v42 | Compute – EC2-instans med Apache och Novatrix webbsida | [v42](./v42) |

---

## v42 – Compute och kom igång

EC2-instans (Amazon Linux 2023, `t3.micro`, region Stockholm `eu-north-1`) med Apache som serverar Novatrix webbsida på instansens publika IP.

```
v42/
├── webb/index.html        # Novatrix webbsida
└── scripts/
    ├── user-data.sh       # installerar Apache + hämtar sidan vid uppstart
    ├── deploy.sh          # (valfritt) skapar hela miljön via AWS CLI i CloudShell
    └── teardown.sh        # tar bort miljön
```

### Återskapa miljön från repot (AWS CloudShell)

```bash
git clone https://github.com/adrianahlborg404-png/AWS-novatrix-mov25.git
cd AWS-novatrix-mov25/v42/scripts
bash deploy.sh            # eller: bash deploy.sh <din-publika-ip> för att öppna SSH
```

Riv ner allt när du är klar:

```bash
bash teardown.sh
```

> Nyckelfilen `*.pem` får aldrig läggas i repot (se `.gitignore`).
