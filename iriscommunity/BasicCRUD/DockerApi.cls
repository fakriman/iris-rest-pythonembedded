Class BasicCRUD.DockerApi Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<!-- Rutas para funciones adicionales -->
<Route Url="/math" Method="POST" Call="MathOperations"/>
<Route Url="/csv-analysis" Method="POST" Call="CSVAnalysis"/>
</Routes>
}

ClassMethod MathOperations() As %Status
{
    Set %response.ContentType = "application/json"
    Set %response.Headers("Access-Control-Allow-Origin") = "*"
    
    Try {
        Set data = ##class(%DynamicObject).%FromJSON(%request.Content)
        Set num1 = data.number1
        Set num2 = data.number2
        
        Set result = ..CalculateMath(num1, num2)
        Write result
        
    } Catch ex {
        Set %response.Status = "500 Internal Server Error"
        Write "{""error"":""" _ ex.DisplayString() _ """}"
    }
    
    Quit $$$OK
}

ClassMethod CalculateMath(num1 As %Numeric, num2 As %Numeric) As %String [ Language = python ]
{
    import json
    
    try:
        # Realizar operaciones matemáticas
        addition = num1 + num2
        subtraction = num1 - num2
        multiplication = num1 * num2
        division = num1 / num2 if num2 != 0 else "División por cero"
        power = num1 ** num2
        
        result = {
            "addition": addition,
            "subtraction": subtraction,
            "multiplication": multiplication,
            "division": division,
            "power": power
        }
        
        return json.dumps(result)
        
    except Exception as e:
        return json.dumps({"error": str(e)})
}

ClassMethod CSVAnalysis() As %Status
{
    Set %response.ContentType = "application/json"
    Set %response.Headers("Access-Control-Allow-Origin") = "*"
    
    Try {
        // Obtener archivo CSV del request
        Set csvContent = %request.GetMimeData("csvFile")
        If '$IsObject(csvContent) {
            Set %response.Status = "400 Bad Request"
            Write "{""error"":""No se encontró archivo CSV""}"
            /// Quit $$$OK
        }
        
        Set csvData = csvContent.Read()
        Set result = ..AnalyzeCSV(csvData)
        Write result
        
    } Catch ex {
        Set %response.Status = "500 Internal Server Error"
        Write "{""error"":""" _ ex.DisplayString() _ """}"
    }
    
    Quit $$$OK
}

ClassMethod AnalyzeCSV(csvData As %String) As %String [ Language = python ]
{
    import json
    import csv
    import io
    import statistics
    
    try:
        # Leer CSV
        csv_file = io.StringIO(csvData)
        reader = csv.DictReader(csv_file)
        data = list(reader)
        
        if not data:
            return json.dumps({"error": "CSV vacío o inválido"})
        
        # Obtener columnas numéricas
        numeric_columns = {}
        for row in data:
            for column, value in row.items():
                try:
                    float(value)
                    if column not in numeric_columns:
                        numeric_columns[column] = []
                    numeric_columns[column].append(float(value))
                except ValueError:
                    continue
        
        # Calcular estadísticas
        results = {}
        for column, values in numeric_columns.items():
            if values:
                results[column] = {
                    "mean": statistics.mean(values),
                    "std": statistics.stdev(values) if len(values) > 1 else 0,
                    "median": statistics.median(values)
                }
        
        return json.dumps(results)
        
    except Exception as e:
        return json.dumps({"error": str(e)})
}

}
