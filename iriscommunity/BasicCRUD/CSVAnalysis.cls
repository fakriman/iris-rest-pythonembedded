Class BasicCRUD.CSVAnalysis Extends %RegisteredObject
{

XData %import [ MimeType = application/python ]
{
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# to Use IRIS inside Python
import iris

# Machine Learning
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.feature_selection import mutual_info_regression, mutual_info_classif

# Estadísticas
from scipy import stats
from scipy.stats import chi2_contingency, pearsonr, spearmanr

# LLM Integration
import openai
import requests
import json
import os
import warnings
from typing import Dict, List, Tuple, Optional, Any
}

/// Do ##class("BasicCRUD.CSVAnalysis").GetCSV("/shared/SomeCSV/Education.csv")
ClassMethod GetCSV(csvFile) [ Language = python ]
{
    # Configuración
    warnings.filterwarnings('ignore')
    plt.style.use('seaborn-v0_8')
    sns.set_palette("husl")

    print("📚 Librerías importadas correctamente")

    # =============================================================================
    # CONFIGURACIÓN DEL LLM
    # =============================================================================

    LLM_CONFIG = {
        # Opción 1: OpenAI (Cloud)
        #'provider': 'ollama',  # 'openai' o 'ollama'
        #'api_key': 'tu-api-key-aqui',  # Solo para OpenAI
        #'model': 'llama3.2',  # gpt-3.5-turbo, gpt-4, etc.
        
        # Opción 2: Ollama (Local)
        'provider': 'ollama',
        'base_url': 'http://host.docker.internal:11434',
        'model': 'llama3.2',  # llama2, codellama, mistral, etc.
        
        'temperature': 0.7,
        'max_tokens': 2000
    }

    # Configuración desde variables de entorno (más seguro)
    if os.getenv('OPENAI_API_KEY'):
        LLM_CONFIG['api_key'] = os.getenv('OPENAI_API_KEY')

    print(f"🤖 LLM configurado: {LLM_CONFIG['provider']} - {LLM_CONFIG['model']}")


    class CSVAnalysisAgent:
        """
        Agente inteligente para análisis exploratorio de datos CSV
        """
        
        def __init__(self, llm_config: Dict):
            self.llm_config = llm_config
            self.df = None
            self.numeric_columns = []
            self.categorical_columns = []
            self.analysis_results = {}
            
            # Configurar cliente LLM
            if llm_config['provider'] == 'openai':
                openai.api_key = llm_config['api_key']
        
        def load_csv(self, file_path: str, **kwargs) -> pd.DataFrame:
            """
            Carga un archivo CSV y realiza análisis inicial
            """
            print(f"📁 Cargando archivo: {file_path}")
            
            try:
                # Intentar diferentes encodings
                encodings = ['utf-8', 'latin-1', 'cp1252', 'iso-8859-1']
                
                for encoding in encodings:
                    try:
                        self.df = pd.read_csv(file_path, encoding=encoding, **kwargs)
                        print(f"✅ Archivo cargado con encoding: {encoding}")
                        break
                    except UnicodeDecodeError:
                        continue
                
                if self.df is None:
                    raise ValueError("No se pudo cargar el archivo con ningún encoding")
                
                # Análisis inicial
                self._analyze_columns()
                self._basic_info()
                
                return self.df
                
            except Exception as e:
                print(f"❌ Error cargando archivo: {e}")
                raise
        
        def _analyze_columns(self):
            """
            Clasifica columnas en numéricas y categóricas
            """
            self.numeric_columns = self.df.select_dtypes(include=[np.number]).columns.tolist()
            self.categorical_columns = self.df.select_dtypes(include=['object', 'category']).columns.tolist()
            
            # Detectar columnas numéricas que podrían ser categóricas
            for col in self.numeric_columns.copy():
                unique_values = self.df[col].nunique()
                if unique_values <= 10 and unique_values < len(self.df) * 0.05:
                    self.categorical_columns.append(col)
                    self.numeric_columns.remove(col)
                    print(f"🔄 Columna '{col}' reclasificada como categórica")
        
        def _basic_info(self):
            """
            Muestra información básica del dataset
            """
            print("\n" + "="*80)
            print("📊 INFORMACIÓN BÁSICA DEL DATASET")
            print("="*80)
            print(f"📏 Dimensiones: {self.df.shape[0]:,} filas × {self.df.shape[1]} columnas")
            print(f"🔢 Columnas numéricas: {len(self.numeric_columns)}")
            print(f"📝 Columnas categóricas: {len(self.categorical_columns)}")
            print(f"❓ Valores faltantes: {self.df.isnull().sum().sum():,}")
            print(f"💾 Memoria utilizada: {self.df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
            
            # Mostrar primeras filas
            print("\n🔍 Primeras 5 filas:")
            print(self.df.head())
        
        def exploratory_analysis(self) -> Dict:
            """
            Realiza análisis exploratorio completo
            """
            print("\n" + "="*80)
            print("🔍 INICIANDO ANÁLISIS EXPLORATORIO COMPLETO")
            print("="*80)
            
            results = {}
            
            # 1. Estadísticas descriptivas
            results['descriptive_stats'] = self._descriptive_statistics()
            
            # 2. Análisis de valores faltantes
            results['missing_analysis'] = self._missing_values_analysis()
            
            # 3. Análisis de correlaciones
            results['correlation_analysis'] = self._correlation_analysis()
            
            # 4. Análisis de distribuciones
            results['distribution_analysis'] = self._distribution_analysis()
            
            # 5. Detección de outliers
            results['outlier_analysis'] = self._outlier_analysis()
            
            # 6. Análisis de variables categóricas
            results['categorical_analysis'] = self._categorical_analysis()
            
            self.analysis_results = results
            return results
        
        def _descriptive_statistics(self) -> Dict:
            """
            Estadísticas descriptivas detalladas
            """
            print("\n📈 Estadísticas Descriptivas")
            
            if self.numeric_columns:
                desc_stats = self.df[self.numeric_columns].describe()
                print(desc_stats)
                
                # Estadísticas adicionales
                additional_stats = pd.DataFrame({
                    'skewness': self.df[self.numeric_columns].skew(),
                    'kurtosis': self.df[self.numeric_columns].kurtosis(),
                    'missing_pct': (self.df[self.numeric_columns].isnull().sum() / len(self.df)) * 100
                })
                
                print("\n📊 Estadísticas Adicionales:")
                print(additional_stats)
                
                return {
                    'basic_stats': desc_stats.to_dict(),
                    'additional_stats': additional_stats.to_dict()
                }
            
            return {}
        
        def _missing_values_analysis(self) -> Dict:
            """
            Análisis detallado de valores faltantes
            """
            print("\n❓ Análisis de Valores Faltantes")
            
            missing_data = pd.DataFrame({
                'Missing_Count': self.df.isnull().sum(),
                'Missing_Percentage': (self.df.isnull().sum() / len(self.df)) * 100
            })
            
            missing_data = missing_data[missing_data['Missing_Count'] > 0].sort_values('Missing_Percentage', ascending=False)
            
            if not missing_data.empty:
                print(missing_data)
                
                # Visualización de valores faltantes
                if len(missing_data) > 0:
                    plt.figure(figsize=(12, 6))
                    sns.heatmap(self.df.isnull(), cbar=True, yticklabels=False, cmap='viridis')
                    plt.title('Patrón de Valores Faltantes')
                    plt.tight_layout()
                    plt.show()
            else:
                print("✅ No hay valores faltantes en el dataset")
            
            return missing_data.to_dict()
        
        def _correlation_analysis(self) -> Dict:
            """
            Análisis completo de correlaciones
            """
            print("\n🔗 Análisis de Correlaciones")
            
            if len(self.numeric_columns) < 2:
                print("⚠️ Se necesitan al menos 2 variables numéricas para análisis de correlación")
                return {}
            
            # Matriz de correlación de Pearson
            corr_pearson = self.df[self.numeric_columns].corr(method='pearson')
            
            # Matriz de correlación de Spearman
            corr_spearman = self.df[self.numeric_columns].corr(method='spearman')
            
            # Visualización
            fig, axes = plt.subplots(1, 2, figsize=(20, 8))
            
            # Heatmap Pearson
            sns.heatmap(corr_pearson, annot=True, cmap='RdBu_r', center=0, 
                    square=True, ax=axes[0], fmt='.2f')
            axes[0].set_title('Correlación de Pearson')
            
            # Heatmap Spearman
            sns.heatmap(corr_spearman, annot=True, cmap='RdBu_r', center=0, 
                    square=True, ax=axes[1], fmt='.2f')
            axes[1].set_title('Correlación de Spearman')
            
            plt.tight_layout()
            plt.show()
            
            # Identificar correlaciones fuertes
            strong_correlations = []
            for i in range(len(corr_pearson.columns)):
                for j in range(i+1, len(corr_pearson.columns)):
                    corr_val = corr_pearson.iloc[i, j]
                    if abs(corr_val) > 0.7:
                        strong_correlations.append({
                            'var1': corr_pearson.columns[i],
                            'var2': corr_pearson.columns[j],
                            'correlation': corr_val
                        })
            
            if strong_correlations:
                print("\n🔥 Correlaciones Fuertes (|r| > 0.7):")
                for corr in strong_correlations:
                    print(f"  • {corr['var1']} ↔ {corr['var2']}: {corr['correlation']:.3f}")
            
            return {
                'pearson': corr_pearson.to_dict(),
                'spearman': corr_spearman.to_dict(),
                'strong_correlations': strong_correlations
            }
        
        def _distribution_analysis(self) -> Dict:
            """
            Análisis de distribuciones de variables numéricas
            """
            print("\n📊 Análisis de Distribuciones")
            
            if not self.numeric_columns:
                print("⚠️ No hay variables numéricas para analizar")
                return {}
            
            # Histogramas y boxplots
            n_cols = min(3, len(self.numeric_columns))
            n_rows = (len(self.numeric_columns) + n_cols - 1) // n_cols
            
            fig, axes = plt.subplots(n_rows * 2, n_cols, figsize=(15, 5 * n_rows))
            if n_rows == 1:
                axes = axes.reshape(2, -1)
            
            distribution_stats = {}
            
            for i, col in enumerate(self.numeric_columns[:9]):  # Limitar a 9 variables
                row = (i // n_cols) * 2
                col_idx = i % n_cols
                
                # Histograma
                self.df[col].hist(bins=30, ax=axes[row, col_idx], alpha=0.7)
                axes[row, col_idx].set_title(f'Distribución: {col}')
                axes[row, col_idx].set_xlabel(col)
                axes[row, col_idx].set_ylabel('Frecuencia')
                
                # Boxplot
                self.df.boxplot(column=col, ax=axes[row + 1, col_idx])
                axes[row + 1, col_idx].set_title(f'Boxplot: {col}')
                
                # Test de normalidad
                stat, p_value = stats.shapiro(self.df[col].dropna().sample(min(5000, len(self.df[col].dropna()))))
                distribution_stats[col] = {
                    'shapiro_stat': stat,
                    'shapiro_p_value': p_value,
                    'is_normal': p_value > 0.05
                }
            
            plt.tight_layout()
            plt.show()
            
            # Resumen de normalidad
            print("\n📈 Test de Normalidad (Shapiro-Wilk):")
            for col, stats_dict in distribution_stats.items():
                status = "✅ Normal" if stats_dict['is_normal'] else "❌ No Normal"
                print(f"  • {col}: {status} (p-value: {stats_dict['shapiro_p_value']:.4f})")
            
            return distribution_stats
        
        def _outlier_analysis(self) -> Dict:
            """
            Detección y análisis de outliers
            """
            print("\n🎯 Análisis de Outliers")
            
            if not self.numeric_columns:
                return {}
            
            outlier_stats = {}
            
            for col in self.numeric_columns:
                Q1 = self.df[col].quantile(0.25)
                Q3 = self.df[col].quantile(0.75)
                IQR = Q3 - Q1
                
                lower_bound = Q1 - 1.5 * IQR
                upper_bound = Q3 + 1.5 * IQR
                
                outliers = self.df[(self.df[col] < lower_bound) | (self.df[col] > upper_bound)]
                
                outlier_stats[col] = {
                    'count': len(outliers),
                    'percentage': (len(outliers) / len(self.df)) * 100,
                    'lower_bound': lower_bound,
                    'upper_bound': upper_bound
                }
            
            # Mostrar resumen
            print("📊 Resumen de Outliers (Método IQR):")
            for col, stats_dict in outlier_stats.items():
                if stats_dict['count'] > 0:
                    print(f"  • {col}: {stats_dict['count']} outliers ({stats_dict['percentage']:.2f}%)")
            
            return outlier_stats
        
        def _categorical_analysis(self) -> Dict:
            """
            Análisis de variables categóricas
            """
            print("\n📝 Análisis de Variables Categóricas")
            
            if not self.categorical_columns:
                print("⚠️ No hay variables categóricas para analizar")
                return {}
            
            categorical_stats = {}
            
            for col in self.categorical_columns[:5]:  # Limitar a 5 variables
                value_counts = self.df[col].value_counts()
                
                categorical_stats[col] = {
                    'unique_values': self.df[col].nunique(),
                    'most_frequent': value_counts.index[0],
                    'most_frequent_count': value_counts.iloc[0],
                    'value_counts': value_counts.to_dict()
                }
                
                # Visualización
                plt.figure(figsize=(10, 6))
                if len(value_counts) <= 20:
                    value_counts.plot(kind='bar')
                    plt.title(f'Distribución de {col}')
                    plt.xticks(rotation=45)
                else:
                    value_counts.head(20).plot(kind='bar')
                    plt.title(f'Top 20 valores de {col}')
                    plt.xticks(rotation=45)
                
                plt.tight_layout()
                plt.show()
                
                print(f"\n📊 {col}:")
                print(f"  • Valores únicos: {categorical_stats[col]['unique_values']}")
                print(f"  • Más frecuente: {categorical_stats[col]['most_frequent']} ({categorical_stats[col]['most_frequent_count']} veces)")
            
            return categorical_stats
        
        def perform_pca(self, n_components: Optional[int] = None, plot: bool = True) -> Dict:
            """
            Realiza Análisis de Componentes Principales (PCA)
            """
            print("\n" + "="*80)
            print("🔬 ANÁLISIS DE COMPONENTES PRINCIPALES (PCA)")
            print("="*80)
            
            if len(self.numeric_columns) < 3:
                print("⚠️ Se necesitan al menos 3 variables numéricas para PCA")
                return {}
            
            # Preparar datos
            data_for_pca = self.df[self.numeric_columns].dropna()
            
            if len(data_for_pca) == 0:
                print("❌ No hay datos suficientes después de eliminar valores faltantes")
                return {}
            
            # Estandarizar datos
            scaler = StandardScaler()
            data_scaled = scaler.fit_transform(data_for_pca)
            
            # Determinar número de componentes
            if n_components is None:
                n_components = min(len(self.numeric_columns), len(data_for_pca))
            
            # Aplicar PCA
            pca = PCA(n_components=n_components)
            pca_result = pca.fit_transform(data_scaled)
            
            # Crear DataFrame con resultados
            pca_df = pd.DataFrame(
                pca_result,
                columns=[f'PC{i+1}' for i in range(n_components)]
            )
            
            # Análisis de varianza explicada
            explained_variance_ratio = pca.explained_variance_ratio_
            cumulative_variance = np.cumsum(explained_variance_ratio)
            
            print(f"📊 Varianza explicada por componente:")
            for i, (var, cum_var) in enumerate(zip(explained_variance_ratio, cumulative_variance)):
                print(f"  • PC{i+1}: {var:.3f} ({var*100:.1f}%) - Acumulada: {cum_var:.3f} ({cum_var*100:.1f}%)")
            
            if plot:
                # Gráfico de varianza explicada
                fig, axes = plt.subplots(2, 2, figsize=(15, 12))
                
                # 1. Scree plot
                axes[0, 0].plot(range(1, len(explained_variance_ratio) + 1), explained_variance_ratio, 'bo-')
                axes[0, 0].set_title('Scree Plot')
                axes[0, 0].set_xlabel('Componente Principal')
                axes[0, 0].set_ylabel('Varianza Explicada')
                axes[0, 0].grid(True)
                
                # 2. Varianza acumulada
                axes[0, 1].plot(range(1, len(cumulative_variance) + 1), cumulative_variance, 'ro-')
                axes[0, 1].axhline(y=0.8, color='k', linestyle='--', alpha=0.7, label='80%')
                axes[0, 1].axhline(y=0.95, color='k', linestyle='--', alpha=0.7, label='95%')
                axes[0, 1].set_title('Varianza Acumulada')
                axes[0, 1].set_xlabel('Componente Principal')
                axes[0, 1].set_ylabel('Varianza Acumulada')
                axes[0, 1].legend()
                axes[0, 1].grid(True)
                
                # 3. Biplot (si hay al menos 2 componentes)
                if n_components >= 2:
                    axes[1, 0].scatter(pca_result[:, 0], pca_result[:, 1], alpha=0.6)
                    axes[1, 0].set_title('PCA Biplot (PC1 vs PC2)')
                    axes[1, 0].set_xlabel(f'PC1 ({explained_variance_ratio[0]*100:.1f}%)')
                    axes[1, 0].set_ylabel(f'PC2 ({explained_variance_ratio[1]*100:.1f}%)')
                    axes[1, 0].grid(True)
                    
                    # Vectores de carga
                    feature_vectors = pca.components_.T
                    for i, (var, vector) in enumerate(zip(self.numeric_columns, feature_vectors)):
                        axes[1, 0].arrow(0, 0, vector[0]*3, vector[1]*3, 
                                    head_width=0.1, head_length=0.1, fc='red', ec='red')
                        axes[1, 0].text(vector[0]*3.2, vector[1]*3.2, var, fontsize=8)
                
                # 4. Heatmap de componentes
                components_df = pd.DataFrame(
                    pca.components_[:min(5, n_components)].T,
                    columns=[f'PC{i+1}' for i in range(min(5, n_components))],
                    index=self.numeric_columns
                )
                
                sns.heatmap(components_df, annot=True, cmap='RdBu_r', center=0, 
                        ax=axes[1, 1], fmt='.2f')
                axes[1, 1].set_title('Matriz de Componentes')
                
                plt.tight_layout()
                plt.show()
            
            # Interpretación de componentes
            components_interpretation = {}
            for i in range(min(3, n_components)):
                component_loadings = pd.Series(
                    pca.components_[i], 
                    index=self.numeric_columns
                ).abs().sort_values(ascending=False)
                
                components_interpretation[f'PC{i+1}'] = {
                    'top_variables': component_loadings.head(3).to_dict(),
                    'variance_explained': explained_variance_ratio[i]
                }
            
            return {
                'pca_data': pca_df,
                'explained_variance_ratio': explained_variance_ratio.tolist(),
                'cumulative_variance': cumulative_variance.tolist(),
                'components': pca.components_.tolist(),
                'components_interpretation': components_interpretation,
                'n_components_80_variance': np.argmax(cumulative_variance >= 0.8) + 1,
                'n_components_95_variance': np.argmax(cumulative_variance >= 0.95) + 1
            }
        
        def generate_insights(self, analysis_results: Dict) -> str:
            """
            Genera insights usando LLM basado en los resultados del análisis
            """
            print("\n" + "="*80)
            print("🤖 GENERANDO INSIGHTS CON IA")
            print("="*80)
            
            # Preparar resumen para el LLM
            summary = self._prepare_analysis_summary(analysis_results)
            
            prompt = f"""
    Eres un experto científico de datos. Analiza los siguientes resultados de análisis exploratorio de datos y proporciona insights valiosos:

    INFORMACIÓN DEL DATASET:
    {summary}

    Por favor, proporciona:
    1. 🔍 INSIGHTS PRINCIPALES: Los hallazgos más importantes del análisis
    2. 🔗 RELACIONES SIGNIFICATIVAS: Correlaciones y patrones interesantes
    3. ⚠️ PROBLEMAS DETECTADOS: Outliers, valores faltantes, distribuciones anómalas
    4. 🎯 VARIABLES PREDICTIVAS: Qué variables serían buenas para modelos predictivos
    5. 📈 RECOMENDACIONES: Próximos pasos para análisis más profundos
    6. 🤖 MODELOS SUGERIDOS: Tipos de modelos de ML que podrían funcionar bien

    Sé específico y actionable en tus recomendaciones.
    """
            
            try:
                response = self._call_llm(prompt)
                print(response)
                return response
            except Exception as e:
                print(f"❌ Error generando insights: {e}")
                return "No se pudieron generar insights automáticos."
        
        def _prepare_analysis_summary(self, results: Dict) -> str:
            """
            Prepara un resumen del análisis para el LLM
            """
            summary_parts = []
            
            # Información básica
            summary_parts.append(f"Dataset: {self.df.shape[0]} filas, {self.df.shape[1]} columnas")
            summary_parts.append(f"Variables numéricas: {len(self.numeric_columns)}")
            summary_parts.append(f"Variables categóricas: {len(self.categorical_columns)}")
            
            # Correlaciones fuertes
            if 'correlation_analysis' in results and 'strong_correlations' in results['correlation_analysis']:
                strong_corrs = results['correlation_analysis']['strong_correlations']
                if strong_corrs:
                    summary_parts.append("\nCorrelaciones fuertes detectadas:")
                    for corr in strong_corrs[:5]:
                        summary_parts.append(f"- {corr['var1']} ↔ {corr['var2']}: {corr['correlation']:.3f}")
            
            # Valores faltantes
            missing_total = self.df.isnull().sum().sum()
            if missing_total > 0:
                summary_parts.append(f"\nValores faltantes: {missing_total} ({(missing_total/(self.df.shape[0]*self.df.shape[1]))*100:.2f}%)")
            
            # Outliers
            if 'outlier_analysis' in results:
                outlier_vars = [var for var, stats in results['outlier_analysis'].items() if stats['count'] > 0]
                if outlier_vars:
                    summary_parts.append(f"\nVariables con outliers: {', '.join(outlier_vars[:5])}")
            
            return "\n".join(summary_parts)
        
        def _call_llm(self, prompt: str) -> str:
            """
            Llama al LLM configurado
            """
            if self.llm_config['provider'] == 'openai':
                response = openai.ChatCompletion.create(
                    model=self.llm_config['model'],
                    messages=[
                        {"role": "system", "content": "Eres un experto científico de datos especializado en análisis exploratorio."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=self.llm_config['temperature'],
                    max_tokens=self.llm_config['max_tokens']
                )
                return response.choices[0].message.content
            
            elif self.llm_config['provider'] == 'ollama':
                response = requests.post(
                    f"{self.llm_config['base_url']}/api/generate",
                    json={
                        "model": self.llm_config['model'],
                        "prompt": prompt,
                        "stream": False,
                        "options": {
                            "temperature": self.llm_config['temperature'],
                            "num_predict": self.llm_config['max_tokens']
                        }
                    }
                )
                return response.json()['response']
            
            else:
                raise ValueError(f"Proveedor LLM no soportado: {self.llm_config['provider']}")
        
        def feature_importance_analysis(self, target_column: str) -> Dict:
            """
            Análisis de importancia de características para una variable objetivo
            """
            print(f"\n🎯 Análisis de Importancia de Características (Target: {target_column})")
            
            if target_column not in self.df.columns:
                print(f"❌ La columna '{target_column}' no existe en el dataset")
                return {}
            
            # Preparar datos
            feature_columns = [col for col in self.numeric_columns if col != target_column]
            
            if not feature_columns:
                print("❌ No hay suficientes variables numéricas para el análisis")
                return {}
            
            # Eliminar filas con valores faltantes
            data_clean = self.df[feature_columns + [target_column]].dropna()
            
            if len(data_clean) == 0:
                print("❌ No hay datos suficientes después de limpiar valores faltantes")
                return {}
            
            X = data_clean[feature_columns]
            y = data_clean[target_column]
            
            # Determinar si es problema de regresión o clasificación
            is_classification = y.nunique() <= 10 and y.dtype == 'object' or y.nunique() <= 5
            
            results = {'target_type': 'classification' if is_classification else 'regression'}
            
            try:
                if is_classification:
                    # Random Forest Classifier
                    rf = RandomForestClassifier(n_estimators=100, random_state=42)
                    rf.fit(X, y)
                    
                    # Mutual Information
                    mi_scores = mutual_info_classif(X, y, random_state=42)
                    
                else:
                    # Random Forest Regressor
                    rf = RandomForestRegressor(n_estimators=100, random_state=42)
                    rf.fit(X, y)
                    
                    # Mutual Information
                    mi_scores = mutual_info_regression(X, y, random_state=42)
                
                # Crear DataFrame con importancias
                importance_df = pd.DataFrame({
                    'Feature': feature_columns,
                    'RF_Importance': rf.feature_importances_,
                    'Mutual_Info': mi_scores
                }).sort_values('RF_Importance', ascending=False)
                
                # Visualización
                fig, axes = plt.subplots(1, 2, figsize=(15, 6))
                
                # Random Forest Importance
                importance_df.set_index('Feature')['RF_Importance'].plot(kind='barh', ax=axes[0])
                axes[0].set_title('Importancia Random Forest')
                axes[0].set_xlabel('Importancia')
                
                # Mutual Information
                importance_df.set_index('Feature')['Mutual_Info'].plot(kind='barh', ax=axes[1])
                axes[1].set_title('Información Mutua')
                axes[1].set_xlabel('Score MI')
                
                plt.tight_layout()
                plt.show()
                
                print("\n📊 Ranking de Importancia:")
                print(importance_df)
                
                results['importance_ranking'] = importance_df.to_dict('records')
                results['top_features'] = importance_df.head(5)['Feature'].tolist()
                
            except Exception as e:
                print(f"❌ Error en análisis de importancia: {e}")
                results['error'] = str(e)
            
            return results
        
        def complete_analysis_report(self, target_column: Optional[str] = None) -> Dict:
            """
            Ejecuta análisis completo y genera reporte
            """
            print("\n" + "="*80)
            print("🚀 EJECUTANDO ANÁLISIS COMPLETO")
            print("="*80)
            
            if self.df is None:
                print("❌ No hay datos cargados. Usa load_csv() primero.")
                return {}
            
            # 1. Análisis exploratorio
            eda_results = self.exploratory_analysis()
            
            # 2. PCA (si es apropiado)
            pca_results = {}
            if len(self.numeric_columns) >= 3:
                pca_results = self.perform_pca()
            
            # 3. Análisis de importancia (si se especifica target)
            importance_results = {}
            if target_column:
                importance_results = self.feature_importance_analysis(target_column)
            
            # 4. Generar insights con IA
            all_results = {
                'eda': eda_results,
                'pca': pca_results,
                'feature_importance': importance_results
            }
            
            insights = self.generate_insights(all_results)
            
            # 5. Compilar reporte final
            final_report = {
                'dataset_info': {
                    'shape': self.df.shape,
                    'numeric_columns': self.numeric_columns,
                    'categorical_columns': self.categorical_columns,
                    'missing_values': self.df.isnull().sum().sum()
                },
                'analysis_results': all_results,
                'ai_insights': insights,
                'recommendations': self._generate_recommendations(all_results)
            }
            
            print("\n" + "="*80)
            print("✅ ANÁLISIS COMPLETO FINALIZADO")
            print("="*80)
            
            return final_report
        
        def _generate_recommendations(self, results: Dict) -> List[str]:
            """
            Genera recomendaciones basadas en los resultados
            """
            recommendations = []
            
            # Recomendaciones basadas en correlaciones
            if 'eda' in results and 'correlation_analysis' in results['eda']:
                strong_corrs = results['eda']['correlation_analysis'].get('strong_correlations', [])
                if strong_corrs:
                    recommendations.append("🔗 Investigar las correlaciones fuertes detectadas para posible multicolinealidad")
            
            # Recomendaciones basadas en PCA
            if 'pca' in results and results['pca']:
                n_comp_80 = results['pca'].get('n_components_80_variance', 0)
                if n_comp_80 < len(self.numeric_columns) * 0.7:
                    recommendations.append(f"📉 Considerar reducción de dimensionalidad: {n_comp_80} componentes explican 80% de varianza")
            
            # Recomendaciones basadas en valores faltantes
            missing_pct = (self.df.isnull().sum().sum() / (self.df.shape[0] * self.df.shape[1])) * 100
            if missing_pct > 5:
                recommendations.append(f"⚠️ Tratar valores faltantes ({missing_pct:.1f}% del dataset)")
            
            # Recomendaciones de modelado
            if len(self.numeric_columns) > 5:
                recommendations.append("🤖 Dataset apropiado para modelos de ensemble (Random Forest, XGBoost)")
            
            if not recommendations:
                recommendations.append("✅ Dataset en buenas condiciones para análisis avanzado")
            
            return recommendations

    print("🤖 Clase CSVAnalysisAgent creada correctamente")

    ### Funciones de Utilidad
    def quick_analysis(csv_path: str, target_column: Optional[str] = None, **csv_kwargs) -> Dict:
        """
        Función de conveniencia para análisis rápido
        
        Args:
            csv_path: Ruta al archivo CSV
            target_column: Columna objetivo para análisis predictivo (opcional)
            **csv_kwargs: Argumentos adicionales para pd.read_csv()
        
        Returns:
            Dict con resultados completos del análisis
        """
        # Crear agente
        agent = CSVAnalysisAgent(LLM_CONFIG)
        
        # Cargar datos
        agent.load_csv(csv_path, **csv_kwargs)
        
        # Ejecutar análisis completo
        return agent.complete_analysis_report(target_column)

    def analyze_sample_data():
        """
        Crea y analiza datos de ejemplo para demostración
        """
        print("📊 Creando dataset de ejemplo...")
        
        # Generar datos sintéticos
        np.random.seed(42)
        n_samples = 1000
        
        data = {
            'age': np.random.normal(35, 10, n_samples),
            'income': np.random.exponential(50000, n_samples),
            'education_years': np.random.normal(14, 3, n_samples),
            'experience': np.random.normal(10, 5, n_samples),
            'satisfaction': np.random.uniform(1, 10, n_samples),
            'department': np.random.choice(['IT', 'Sales', 'Marketing', 'HR', 'Finance'], n_samples),
            'performance_score': np.random.normal(75, 15, n_samples)
        }
        
        # Crear correlaciones artificiales
        data['income'] = data['income'] + data['education_years'] * 2000 + np.random.normal(0, 5000, n_samples)
        data['performance_score'] = (data['performance_score'] + 
                                    data['experience'] * 2 + 
                                    data['satisfaction'] * 3 + 
                                    np.random.normal(0, 10, n_samples))
        
        # Crear DataFrame
        df_sample = pd.DataFrame(data)
        
        # Introducir algunos valores faltantes
        missing_indices = np.random.choice(df_sample.index, size=50, replace=False)
        df_sample.loc[missing_indices, 'satisfaction'] = np.nan
        
        # Guardar como CSV temporal
        sample_path = 'sample_data.csv'
        df_sample.to_csv(sample_path, index=False)
        
        print(f"✅ Dataset de ejemplo guardado en: {sample_path}")
        print(f"📏 Dimensiones: {df_sample.shape}")
        
        return sample_path

    print("🛠️ Funciones de utilidad creadas")

    # =============================================================================
    # ANALIZA TU PROPIO ARCHIVO CSV
    # =============================================================================

    # 📁 CONFIGURACIÓN: Cambia estos valores según tu archivo
    CSV_FILE_PATH = csvFile ###"Education.csv"  # 👈 Cambia por la ruta de tu archivo
    TARGET_COLUMN = None  # 👈 Opcional: especifica columna objetivo para análisis predictivo

    # Parámetros adicionales para pd.read_csv() si es necesario
    CSV_PARAMS = {
        # 'sep': ',',           # Separador (por defecto coma)
        # 'decimal': '.',       # Separador decimal
        # 'encoding': 'utf-8',  # Encoding del archivo
        # 'header': 0,          # Fila con nombres de columnas
    }

    # Ejecutar análisis
    try:
        print(f"🔍 Analizando archivo: {CSV_FILE_PATH}")
        
        # Opción 1: Análisis rápido (una sola función)
        # results = quick_analysis(CSV_FILE_PATH, TARGET_COLUMN, **CSV_PARAMS)
        
        # Opción 2: Análisis paso a paso (más control)
        agent = CSVAnalysisAgent(LLM_CONFIG)
        df = agent.load_csv(CSV_FILE_PATH, **CSV_PARAMS)
        results = agent.complete_analysis_report(TARGET_COLUMN)
        
        print("\n✅ ¡Análisis completado exitosamente!")
        
    except FileNotFoundError:
        print(f"❌ Archivo no encontrado: {CSV_FILE_PATH}")
        print("💡 Asegúrate de que la ruta del archivo sea correcta")
    except Exception as e:
        print(f"❌ Error durante el análisis: {e}")
        print("💡 Verifica el formato del archivo y los parámetros de configuración")
}

}
