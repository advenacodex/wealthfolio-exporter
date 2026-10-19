# wealthfolio_exporter

Script que exporta las posiciones (*holdings*) de [Wealthfolio](https://wealthfolio.app) a CSV y a tabla Markdown, una fila por cuenta y valor.

`holdings.sh` es la misma versión que corre en producción en kali (`/volume2/docker/scripts/holdings.sh`).

## Qué hace

Lee la base de datos SQLite de Wealthfolio (`wealthfolio.db`) y, para cada cuenta, toma su **último snapshot** de `holdings_snapshots`. Los snapshots ya tienen aplicados los splits (p. ej. el 4:1 de Apple), el coste medio y los lotes, así que las cifras coinciden con las de la aplicación. Sumar transacciones a mano fallaba con los splits.

El script solo lee la base de datos; no la modifica.

## Requisitos

- `bash`, `sqlite3` (con soporte JSON) y `python3`.

## Uso

```bash
./holdings.sh                          # $WEALTHFOLIO_DB, o la ruta de producción en kali
./holdings.sh /ruta/a/wealthfolio.db   # ruta propia (tiene prioridad)
export WEALTHFOLIO_DB=~/copia/wealthfolio.db   # para no repetir la ruta en el Mac
```

Orden de prioridad: argumento, variable `WEALTHFOLIO_DB`, y por último `/volume2/docker/volumes/wealthfolio/wealthfolio.db`. Esa ruta solo existe en kali, así que en el Mac hay que usar el argumento o la variable con la ruta de una **copia** de la base de datos.

Ejecútalo sobre una copia, no sobre la base de datos en uso, para no interferir con Wealthfolio.

## Salida

Se escribe en el directorio actual, con la fecha del día:

- `YYYYMMDD_holdings.csv`
- `YYYYMMDD_holdings.md` (misma tabla en Markdown)

Columnas: `Account`, `Ticker`, `Name`, `First_Buy_Date`, `Shares`, `Market` (MIC del mercado), `Avg_Price`, `Currency`. Solo aparecen posiciones con `Shares > 0`.

Estos ficheros contienen datos de tu cartera, por eso `.gitignore` excluye `*_holdings.csv` y `*_holdings.md`. No los subas al repositorio.

## Notas

- La variable `WEALTHFOLIO_DB` está solo en el repo; el `holdings.sh` de kali todavía no la tiene (se comporta igual por defecto). Mantén los dos ficheros iguales: cualquier cambio hay que hacerlo en los dos sitios.
- Existe también el addon `holdings-exporter` (botón de descarga dentro de la interfaz de Wealthfolio), que está en el clon de Wealthfolio, no aquí. **No está instalado en producción.**
- Producción usa la imagen oficial `wealthfolio/wealthfolio:3.9.0`.
