Portfolio exporter

Con el script y el desarrollo del complemento (*addon*), hemos logrado una solución robusta para exportar tus inversiones. Aquí tienes los puntos clave de lo que hemos conseguido:

### 1. Precisión con Splits y Eventos Corporativos
El mayor logro ha sido cambiar la lógica de cálculo. En lugar de sumar transacciones manualmente (lo cual fallaba con situaciones como el split 4:1 de Apple), ahora el script utiliza la tabla `holdings_snapshots`. 
- **Resultado:** Los valores de participaciones (*shares*) y el precio medio (*average cost*) ahora coinciden exactamente con lo que ves en la aplicación.

### 2. Automatización via Script (`holdings_csv.sh`)
Hemos creado un script de Bash que:
- Localiza automáticamente tu base de datos de Wealthfolio.
- Ejecuta una consulta SQL compleja que extrae los datos directamente de los snapshots JSON.
- Genera un archivo CSV profesional con columnas claras: Cuenta, Ticker, Nombre, Fecha de inicio, Acciones, Mercado, Precio Medio y Moneda.

### 3. Integración en la Interfaz (`holdings-exporter`)
No solo tenemos un script técnico, sino que hemos desarrollado un **Addon completo** para la aplicación:
- **Interfaz Visual:** Una página dedicada dentro de Wealthfolio con un botón de descarga.
- **Simplicidad:** Cualquier usuario puede exportar sus datos sin tocar la terminal, simplemente haciendo clic en "Download Holdings CSV".
- **Consistencia:** Utiliza la API interna de Wealthfolio (`ctx.api.portfolio.getHoldings`), garantizando que los datos exportados sean siempre los más recientes y precisos.

### 4. Datos Enriquecidos
La exportación no solo da los nombres, sino que incluye metadatos importantes como el **Exchange MIC** (identificador de mercado) y la **Inception Date** (la fecha de tu primera compra), lo cual es ideal para importar estos datos en otras herramientas de análisis o para llevar un control fiscal.

En resumen, hemos pasado de tener discrepancias en el número de acciones a tener un **sistema de exportación profesional y exacto**, disponible tanto por terminal como por interfaz gráfica.