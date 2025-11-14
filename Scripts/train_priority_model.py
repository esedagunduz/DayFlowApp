
import os
import numpy as np
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_absolute_error
try:
    import coremltools as ct
except Exception as e:
    ct = None
    print("[WARN] coremltools bulunamadı. Kurulum: pip install coremltools")


def calculate_urgency_score(days_to_due):
    """Eisenhower Matrisi - Aciliyet Skoru"""
    urgency = np.zeros_like(days_to_due, dtype=float)
    urgency[days_to_due < 0] = 1.0
    urgency[days_to_due == 0] = 0.85
    mask = (days_to_due >= 1) & (days_to_due <= 3)
    urgency[mask] = 0.75 - (days_to_due[mask] - 1) * 0.05
    mask = (days_to_due >= 4) & (days_to_due <= 7)
    urgency[mask] = 0.60 - (days_to_due[mask] - 4) * 0.05
    mask = (days_to_due >= 8) & (days_to_due <= 14)
    urgency[mask] = 0.35 - (days_to_due[mask] - 8) * 0.025
    mask = (days_to_due >= 15) & (days_to_due <= 30)
    urgency[mask] = 0.20 - (days_to_due[mask] - 15) * 0.01
    urgency[days_to_due > 30] = 0.05
    return urgency


def calculate_cognitive_load(estimated_minutes, effort_level):
    """Bilişsel Yük Teorisi - Düşük yük = yüksek skor (Quick Wins için)"""
    time_factor = 1.0 - np.clip(estimated_minutes / 120.0, 0, 1)
    difficulty_factor = 1.0 - (effort_level / 2.0)
    cognitive_ease = (time_factor * 0.4 + difficulty_factor * 0.6)
    quick_win_bonus = np.zeros_like(estimated_minutes, dtype=float)
    quick_win_mask = (estimated_minutes <= 15) & (effort_level == 0)
    quick_win_bonus[quick_win_mask] = 0.15
    return cognitive_ease + quick_win_bonus


def calculate_challenge_score(estimated_minutes, effort_level):
    """Zorluk Skoru (Eat the Frog için) - Yüksek zorluk = yüksek skor"""
    time_challenge = np.clip(estimated_minutes / 120.0, 0, 1)
    difficulty_challenge = effort_level / 2.0
    challenge = (time_challenge * 0.4 + difficulty_challenge * 0.6)
    deep_work_bonus = np.zeros_like(estimated_minutes, dtype=float)
    deep_work_mask = (estimated_minutes >= 60) & (effort_level >= 1)
    deep_work_bonus[deep_work_mask] = 0.15
    return challenge + deep_work_bonus


def calculate_importance_score(user_priority, effort_level, estimated_minutes):
    """Önem Skoru (Eisenhower Matrisi)"""
    user_importance = user_priority / 3.0
    strategic_bonus = np.zeros_like(user_priority, dtype=float)
    strategic_mask = (effort_level >= 1) & (estimated_minutes > 60)
    strategic_bonus[strategic_mask] = 0.1
    return np.clip(user_importance + strategic_bonus, 0, 1)


def synthesize_dataset(n: int = 8000, seed: int = 42):

    rng = np.random.default_rng(seed)

    days_to_due = rng.integers(-3, 61, size=n)
    estimated_minutes = rng.integers(5, 181, size=n)
    effort_level = rng.integers(0, 3, size=n)
    user_priority = rng.integers(0, 4, size=n)
    strategy_preference = rng.integers(0, 3, size=n)

    urgency = calculate_urgency_score(days_to_due)
    importance = calculate_importance_score(user_priority, effort_level, estimated_minutes)
    cognitive_ease = calculate_cognitive_load(estimated_minutes, effort_level)
    challenge = calculate_challenge_score(estimated_minutes, effort_level)

    priority_score = np.zeros(n, dtype=float)
    
    for i in range(n):
 
        if strategy_preference[i] == 0: 
           
            strategy_factor = cognitive_ease[i] * 0.45

            if estimated_minutes[i] <= 15 and effort_level[i] == 0:
                strategy_factor *= 1.4 
            elif estimated_minutes[i] <= 30 and effort_level[i] <= 1:
                strategy_factor *= 1.2  
            elif estimated_minutes[i] >= 90 and effort_level[i] == 2:
                strategy_factor *= 0.6  
            
            base_score = urgency[i] * 0.30 + importance[i] * 0.25 + strategy_factor
            
        elif strategy_preference[i] == 1: 
            base_score = (
                urgency[i] * 0.35 +
                importance[i] * 0.30 +
                cognitive_ease[i] * 0.20 +
                challenge[i] * 0.15
            )
            
        else:   
            strategy_factor = challenge[i] * 0.45

            if estimated_minutes[i] >= 90 and effort_level[i] == 2:
                strategy_factor *= 1.4  
            elif estimated_minutes[i] >= 45 and effort_level[i] >= 1:
                strategy_factor *= 1.2  
            elif estimated_minutes[i] <= 15 and effort_level[i] == 0:
                strategy_factor *= 0.6  
            
            base_score = urgency[i] * 0.30 + importance[i] * 0.25 + strategy_factor

        if urgency[i] > 0.7 and importance[i] > 0.66:
            eisenhower_multiplier = 1.0 + (urgency[i] * importance[i] * 0.35)
            base_score *= eisenhower_multiplier
 
            if strategy_preference[i] == 0 and effort_level[i] == 0 and estimated_minutes[i] <= 15:
                base_score *= 1.25 

            if strategy_preference[i] == 2 and effort_level[i] == 2 and estimated_minutes[i] >= 60:
                base_score *= 1.25  
        
        priority_score[i] = base_score
    
    priority_score = np.clip(priority_score * 100, 0, 120)

    noise = rng.normal(0, 1.5, size=n)
    priority_score = np.clip(priority_score + noise, 0, 120)
    
    X = np.column_stack([
        days_to_due, 
        estimated_minutes, 
        effort_level, 
        user_priority,
        strategy_preference
    ]).astype(np.float32)
    
    y = priority_score.astype(np.float32)
    
    return X, y


def main():
    print("=" * 70)
    print("SAF MAKİNE ÖĞRENMESİ MODELİ v4.0")
    print("=" * 70)
    print("\n✨ Özellikler:")
    print("• Eisenhower mantığı VERİ İÇİNDE (model öğrenecek)")
    print("• Strateji bonusları VERİ İÇİNDE (model öğrenecek)")
    print("• Swift tarafında SIFIR manuel müdahale")
    print("• Model %100 kendi başına karar veriyor")
    print()

    print(" 8000 sentetik görev üretiliyor...")
    X, y = synthesize_dataset(n=8000)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    print(" Model eğitiliyor (daha güçlü parametreler)...")
    model = GradientBoostingRegressor(
        n_estimators=300,        
        learning_rate=0.08,      
        max_depth=6,             
        min_samples_split=10,    
        min_samples_leaf=5,      
        subsample=0.8,
        random_state=42
    )
    model.fit(X_train, y_train)
    
    pred_train = model.predict(X_train)
    pred_test = model.predict(X_test)
    
    print("\n" + "=" * 70)
    print("MODEL PERFORMANSI")
    print("=" * 70)
    print(f"Train R² Skoru: {r2_score(y_train, pred_train):.4f}")
    print(f"Test R² Skoru:  {r2_score(y_test, pred_test):.4f}")
    print(f"Train MAE:      {mean_absolute_error(y_train, pred_train):.2f}")
    print(f"Test MAE:       {mean_absolute_error(y_test, pred_test):.2f}")
    
    feature_names = ["days_to_due", "estimated_minutes", "effort_level", 
                     "user_priority", "strategy_preference"]
    importances = model.feature_importances_
    print("\n" + "=" * 70)
    print("ÖZELLİK ÖNEMLERİ")
    print("=" * 70)
    for name, imp in zip(feature_names, importances):
        print(f"{name:25s}: {imp:.3f} ({'█' * int(imp * 50)})")
    
    print("\n" + "=" * 70)
    print("GERÇEK GÖREV TESTLERİ")
    print("=" * 70)
    
    test_cases = [
        {
            "desc": "💰 Fatura Öde",
            "features": [0, 5, 0, 3]  
        },
        {
            "desc": "📧 E-posta Yanıtla",
            "features": [0, 10, 0, 1]  
        },
        {
            "desc": "📊 Proje Raporu",
            "features": [1, 120, 2, 3] 
        },
        {
            "desc": "📝 Toplantı Notları",
            "features": [3, 45, 1, 1]  
        },
        {
            "desc": "💻 Yeni Özellik",
            "features": [7, 180, 2, 2]  
        }
    ]
    
    strategies = ["Quick Wins", "Balanced", "Eat the Frog"]
    
    for strat_idx, strat_name in enumerate(strategies):
        print(f"\n{'🎯' if strat_idx == 0 else '⚖️' if strat_idx == 1 else '🐸'} {strat_name.upper()}")
        print("-" * 70)
        
        results = []
        for case in test_cases:
            features = np.array([case['features'] + [strat_idx]], dtype=np.float32)
            score = model.predict(features)[0]
            results.append((case['desc'], score))
        
        results.sort(key=lambda x: x[1], reverse=True)
        
        for rank, (desc, score) in enumerate(results, 1):
            print(f"  {rank}. {desc:25s} → {score:5.1f}/100")
    
    if ct is None:
        print("\n[UYARI] Core ML export için coremltools kurulu değil")
        return
    
    print("\n" + "=" * 70)
    print("CORE ML EXPORT")
    print("=" * 70)
    
    mlmodel = ct.converters.sklearn.convert(
        model,
        input_features=["days_to_due", "estimated_minutes", "effort_level", 
                        "user_priority", "strategy_preference"],
        output_feature_names="priority_score",
    )
    
    mlmodel.author = "DayFlow - Pure ML v4.0"
    mlmodel.license = "MIT"
    mlmodel.short_description = (
        "100% makine öğrenmesine dayalı görev önceliklendirme. "
        "Eisenhower Matrisi ve strateji mantığı VERİ İÇİNDE öğrenildi. "
        "Swift tarafında manuel müdahale YOK."
    )
    
    mlmodel.input_description["days_to_due"] = (
        "Bitiş tarihine kalan gün sayısı. "
        "Negatif = geçmiş, 0 = bugün, pozitif = gelecek"
    )
    mlmodel.input_description["estimated_minutes"] = (
        "Tahmini süre (dakika). 5-180 arası"
    )
    mlmodel.input_description["effort_level"] = (
        "Zorluk seviyesi. 0 = Kolay, 1 = Orta, 2 = Zor"
    )
    mlmodel.input_description["user_priority"] = (
        "Kullanıcı önceliği. 0 = Düşük, 1 = Orta, 2 = Yüksek, 3 = Acil"
    )
    mlmodel.input_description["strategy_preference"] = (
        "Kullanıcı stratejisi. "
        "0 = Quick Wins, 1 = Balanced, 2 = Eat the Frog"
    )
    
    mlmodel.output_description["priority_score"] = (
        "Öncelik skoru (0-120). Yüksek = daha önce yapılmalı. "
        "Model Eisenhower Matrisi'ni ve strateji mantığını otomatik uygular."
    )
    
    out_dir = os.path.join(os.path.dirname(__file__), "..", "DayFlow", "ModelsML")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "PriorityModel.mlmodel")
    mlmodel.save(out_path)
    
    print(f"✓ Model kaydedildi: {os.path.abspath(out_path)}")
    print("\n" + "=" * 70)
    print("SWIFT KULLANIMI")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()