# wealthfolio-exporter

[English](README.md)

Exporta las posiciones (*holdings*) de [Wealthfolio](https://wealthfolio.app) a **CSV** y a tabla **Markdown**, una fila por cuenta y valor.

## Funcionamiento

Lee la base de datos SQLite de Wealthfolio (`wealthfolio.db`) en solo lectura y toma el **último snapshot** de cada cuenta de `holdings_snapshots`. Los snapshots ya incluyen splits, coste medio y lotes, así que las cifras coinciden con las de la aplicación. Es seguro ejecutarlo con Wealthfolio en marcha (SQLite WAL admite lectores concurrentes).

## Requisitos

`bash`, `sqlite3` (con soporte JSON), `python3` y acceso de lectura a `wealthfolio.db`.

## Uso

```bash
./holdings.sh [/ruta/a/wealthfolio.db]
```

Sin argumento usa la ruta por defecto de la línea `DB=` de `holdings.sh`; edítala según tu instalación.

Para trabajar sobre una copia, no copies el `.db` directamente (los cambios pendientes están en el `-wal`). Usa:

```bash
sqlite3 /ruta/a/wealthfolio.db ".backup copia.db"
./holdings.sh copia.db
```

## Salida

Se escribe en el directorio actual:

- `YYYYMMDD_holdings.csv`
- `YYYYMMDD_holdings.md`

Columnas: `Account`, `Ticker`, `Name`, `First_Buy_Date`, `Shares`, `Market` (código MIC), `Avg_Price`, `Currency`, `Last_Price`, `Last_Price_Date`. Solo posiciones con `Shares > 0`.

`Last_Price` es el último cierre guardado en la tabla `quotes` de Wealthfolio (en la moneda de la cotización) y `Last_Price_Date` su fecha. Conviene mirar la fecha: un activo cuyo proveedor de cotizaciones ha dejado de actualizarse conserva su precio antiguo. Ambos quedan vacíos si el activo no tiene cotizaciones.

## Programación

**cron**

```cron
0 22 * * * umask 077; cd /ruta/a/scripts && ./holdings.sh >> holdings.log 2>&1
```

**n8n** — si n8n corre en un contenedor sin `sqlite3`/`python3` ni acceso a la base de datos, usa dos nodos SSH (misma credencial) tras un Schedule Trigger (`0 22 * * *`):

```bash
# 1. Limpieza: conserva en archive/ los del día 1 de mes y borra el resto de exportaciones
HOLDINGS=/ruta/de/salida && mkdir -p ${HOLDINGS}/archive && find ${HOLDINGS} -maxdepth 1 \( -name '*_holdings.csv' -o -name '*_holdings.md' \) | while read f; do if basename "$f" | grep -qE '^[0-9]{6}01'; then mv "$f" ${HOLDINGS}/archive/; else rm "$f"; fi; done

# 2. Ejecutar y mover
cd /ruta/a/scripts && bash holdings.sh && DATE=$(date +%Y%m%d) && cp ${DATE}*.csv ${DATE}*.md /ruta/de/salida/ && rm ${DATE}*.csv ${DATE}*.md
```

Usa la misma ruta de salida en ambos. La limpieza **borra** los `*_holdings.csv`/`*_holdings.md` de ese directorio que no sean del día 1 de mes.

## Privacidad

Los ficheros generados contienen datos de tu cartera. `.gitignore` excluye `*_holdings.csv` y `*_holdings.md`; no los subas al repositorio. El script nunca escribe en la base de datos.
