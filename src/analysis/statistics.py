"""
Statistical analysis functions for fish community data.

Includes:
- Habitat comparison (Welch's t-test)
- Temporal trend analysis (Mann-Kendall)
- Diversity indices (Shannon, Simpson)
- Regression modeling
"""

import numpy as np
import pandas as pd
from scipy import stats
from typing import Dict, Any, Tuple
from dataclasses import dataclass


@dataclass
class TTestResult:
    """Results from Welch's t-test."""
    group1_mean: float
    group1_std: float
    group1_n: int
    group2_mean: float
    group2_std: float
    group2_n: int
    t_statistic: float
    p_value: float
    cohens_d: float
    significant: bool

    def to_dict(self) -> Dict[str, Any]:
        return {
            "group1": {
                "mean": round(float(self.group1_mean), 3),
                "std": round(float(self.group1_std), 3),
                "n": int(self.group1_n)
            },
            "group2": {
                "mean": round(float(self.group2_mean), 3),
                "std": round(float(self.group2_std), 3),
                "n": int(self.group2_n)
            },
            "t_statistic": round(float(self.t_statistic), 3),
            "p_value": round(float(self.p_value), 6),
            "cohens_d": round(float(self.cohens_d), 3),
            "significant": bool(self.significant)
        }


@dataclass
class MannKendallResult:
    """Results from Mann-Kendall trend test."""
    sens_slope: float
    p_value: float
    trend: str  # "increasing", "decreasing", or "no trend"
    significant: bool

    def to_dict(self) -> Dict[str, Any]:
        return {
            "sens_slope": round(float(self.sens_slope), 4),
            "p_value": round(float(self.p_value), 4),
            "trend": str(self.trend),
            "significant": bool(self.significant)
        }


def welch_t_test(
    group1: np.ndarray,
    group2: np.ndarray,
    alpha: float = 0.05
) -> TTestResult:
    """
    Perform Welch's t-test for comparing two groups with unequal variances.

    Args:
        group1: First sample array
        group2: Second sample array
        alpha: Significance level

    Returns:
        TTestResult with test statistics
    """
    # Remove NaN values
    group1 = group1[~np.isnan(group1)]
    group2 = group2[~np.isnan(group2)]

    # Calculate statistics
    t_stat, p_val = stats.ttest_ind(group1, group2, equal_var=False)

    # Cohen's d effect size
    pooled_std = np.sqrt((group1.std()**2 + group2.std()**2) / 2)
    cohens_d = (group1.mean() - group2.mean()) / pooled_std if pooled_std > 0 else 0

    return TTestResult(
        group1_mean=group1.mean(),
        group1_std=group1.std(),
        group1_n=len(group1),
        group2_mean=group2.mean(),
        group2_std=group2.std(),
        group2_n=len(group2),
        t_statistic=t_stat,
        p_value=p_val,
        cohens_d=abs(cohens_d),
        significant=p_val < alpha
    )


def mann_kendall_test(
    values: np.ndarray,
    alpha: float = 0.05
) -> MannKendallResult:
    """
    Perform Mann-Kendall trend test with Sen's slope estimator.

    Args:
        values: Time series values (in chronological order)
        alpha: Significance level

    Returns:
        MannKendallResult with trend statistics
    """
    n = len(values)

    # Calculate S statistic
    s = 0
    for i in range(n - 1):
        for j in range(i + 1, n):
            diff = values[j] - values[i]
            if diff > 0:
                s += 1
            elif diff < 0:
                s -= 1

    # Calculate variance of S
    var_s = (n * (n - 1) * (2 * n + 5)) / 18

    # Calculate Z statistic
    if s > 0:
        z = (s - 1) / np.sqrt(var_s)
    elif s < 0:
        z = (s + 1) / np.sqrt(var_s)
    else:
        z = 0

    # Calculate p-value (two-tailed)
    p_value = 2 * (1 - stats.norm.cdf(abs(z)))

    # Sen's slope estimator
    slopes = []
    for i in range(n - 1):
        for j in range(i + 1, n):
            slopes.append((values[j] - values[i]) / (j - i))
    sens_slope = np.median(slopes) if slopes else 0

    # Determine trend direction
    if p_value < alpha:
        trend = "increasing" if sens_slope > 0 else "decreasing"
    else:
        trend = "no significant trend"

    return MannKendallResult(
        sens_slope=sens_slope,
        p_value=p_value,
        trend=trend,
        significant=p_value < alpha
    )


def calculate_shannon_diversity(counts: np.ndarray) -> float:
    """
    Calculate Shannon diversity index (H').

    H' = -sum(p_i * ln(p_i))

    Args:
        counts: Array of species counts

    Returns:
        Shannon diversity index
    """
    counts = counts[counts > 0]  # Remove zeros
    total = counts.sum()
    if total == 0:
        return 0.0

    proportions = counts / total
    return -np.sum(proportions * np.log(proportions))


def calculate_simpson_diversity(counts: np.ndarray) -> float:
    """
    Calculate Simpson diversity index (1 - D).

    D = sum(p_i^2)
    Simpson = 1 - D (probability of interspecific encounter)

    Args:
        counts: Array of species counts

    Returns:
        Simpson diversity index (1 - D)
    """
    counts = counts[counts > 0]
    total = counts.sum()
    if total == 0:
        return 0.0

    proportions = counts / total
    return 1 - np.sum(proportions ** 2)


def calculate_evenness(shannon_h: float, species_count: int) -> float:
    """
    Calculate Pielou's evenness index (J').

    J' = H' / ln(S)

    Args:
        shannon_h: Shannon diversity index
        species_count: Number of species

    Returns:
        Evenness index (0-1)
    """
    if species_count <= 1:
        return 0.0
    return shannon_h / np.log(species_count)


def compare_habitats(df: pd.DataFrame) -> Dict[str, Any]:
    """
    Compare fish density and richness between Tidal Creek and Main Channel.

    Args:
        df: DataFrame with habitat_code, count_per_m2, species_count columns

    Returns:
        Dictionary with comparison statistics
    """
    tc_data = df[df["habitat_code"] == "TC"]
    mc_data = df[df["habitat_code"] == "BNMC"]

    density_test = welch_t_test(
        tc_data["count_per_m2"].values,
        mc_data["count_per_m2"].values
    )

    richness_test = welch_t_test(
        tc_data["species_count"].values,
        mc_data["species_count"].values
    )

    return {
        "tidal_creek": {
            "mean_density": round(tc_data["count_per_m2"].mean(), 2),
            "std_density": round(tc_data["count_per_m2"].std(), 2),
            "mean_richness": round(tc_data["species_count"].mean(), 2),
            "std_richness": round(tc_data["species_count"].std(), 2),
            "n": len(tc_data)
        },
        "main_channel": {
            "mean_density": round(mc_data["count_per_m2"].mean(), 2),
            "std_density": round(mc_data["count_per_m2"].std(), 2),
            "mean_richness": round(mc_data["species_count"].mean(), 2),
            "std_richness": round(mc_data["species_count"].std(), 2),
            "n": len(mc_data)
        },
        "density_test": density_test.to_dict(),
        "richness_test": richness_test.to_dict()
    }


def analyze_temporal_trends(df: pd.DataFrame) -> Dict[str, Any]:
    """
    Analyze temporal trends in fish density and richness.

    Args:
        df: DataFrame with year, count_per_m2, species_count columns

    Returns:
        Dictionary with trend analysis results
    """
    # Annual means
    annual = df.groupby("year").agg({
        "count_per_m2": "mean",
        "species_count": "mean"
    }).reset_index()

    density_trend = mann_kendall_test(annual["count_per_m2"].values)
    richness_trend = mann_kendall_test(annual["species_count"].values)

    return {
        "years": annual["year"].tolist(),
        "annual_density": annual["count_per_m2"].round(2).tolist(),
        "annual_richness": annual["species_count"].round(2).tolist(),
        "density_trend": density_trend.to_dict(),
        "richness_trend": richness_trend.to_dict()
    }


if __name__ == "__main__":
    # Quick test
    print("Testing statistical functions...")

    # Test t-test
    g1 = np.array([5.2, 6.1, 4.8, 5.5, 6.0, 5.8])
    g2 = np.array([3.1, 2.9, 3.5, 3.2, 2.8])
    result = welch_t_test(g1, g2)
    print(f"\nT-test result: t={result.t_statistic:.3f}, p={result.p_value:.4f}")
    print(f"  Cohen's d: {result.cohens_d:.3f}")

    # Test Mann-Kendall
    ts = np.array([1.2, 1.5, 1.8, 2.1, 2.0, 2.5, 2.8])
    mk_result = mann_kendall_test(ts)
    print(f"\nMann-Kendall result: slope={mk_result.sens_slope:.4f}, trend={mk_result.trend}")

    # Test diversity
    counts = np.array([100, 50, 25, 12, 6, 3])
    shannon = calculate_shannon_diversity(counts)
    simpson = calculate_simpson_diversity(counts)
    evenness = calculate_evenness(shannon, len(counts))
    print(f"\nDiversity indices:")
    print(f"  Shannon H': {shannon:.3f}")
    print(f"  Simpson: {simpson:.3f}")
    print(f"  Evenness: {evenness:.3f}")
