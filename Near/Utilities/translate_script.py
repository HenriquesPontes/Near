import json

translations = {
    "1 Device Found": "1 Dispositivo Encontrado",
    "An unknown device (%@) is following you. It was detected at multiple distant locations.": "Um dispositivo desconhecido (%@) está seguindo você. Foi detectado em vários locais distantes.",
    "App Badge": "Aviso no Ícone do App",
    "Apple Devices": "Dispositivos Apple",
    "Apple electronics and wearables": "Eletrônicos e wearables Apple",
    "Detects Bluetooth emissions from popular smart glasses like Ray-Ban Meta and other smart glasses.": "Detecta emissões Bluetooth de óculos inteligentes populares como Ray-Ban Meta e outros.",
    "Device Nearby": "Dispositivo Próximo",
    "devices": "dispositivos",
    "Devices Found": "Dispositivos Encontrados",
    "Enable Cooldown": "Ativar Tempo de Espera",
    "Estimated distance:": "Distância estimada:",
    "Filter": "Filtro",
    "ID:": "ID:",
    "meters": "metros",
    "min": "min",
    "Oakley Meta Vanguard": "Oakley Meta Vanguard",
    "Off": "Desligado",
    "Possible Tracking Detected": "Possível Rastreamento Detectado",
    "Privacy Threat Profile": "Perfil de Ameaça à Privacidade",
    "Project Aria": "Project Aria",
    "Proximity Radar": "Radar de Proximidade",
    "Radar mode is actively monitoring for new devices in the background.": "O modo radar está monitorando ativamente novos dispositivos em segundo plano.",
    "Radar mode is paused. Tap to enable background scanning.": "O modo radar está pausado. Toque para ativar o escaneamento em segundo plano.",
    "Ray-Ban Meta, Oakley Meta, Oakley Meta Vanguard, Meta Ray-Ban Display, Project Aria, Orion": "Ray-Ban Meta, Oakley Meta, Oakley Meta Vanguard, Meta Ray-Ban Display, Project Aria, Orion",
    "Samsung Devices": "Dispositivos Samsung",
    "Samsung electronics and wearables": "Eletrônicos e wearables Samsung",
    "Scan Completed": "Escaneamento Concluído",
    "Searching for Devices...": "Buscando dispositivos...",
    "Simulation Devices": "Dispositivos Simulados",
    "Trusted": "Confiável",
    "Try Again": "Tentar Novamente",
    "Untrust": "Remover Confiança"
}

with open("/Users/admin/Developer/Near/Near/Localizable.xcstrings", "r") as f:
    data = json.load(f)

for key, pt_value in translations.items():
    if key in data["strings"]:
        if "localizations" not in data["strings"][key]:
            data["strings"][key]["localizations"] = {}
        
        # Add pt
        data["strings"][key]["localizations"]["pt"] = {
            "stringUnit": {
                "state": "translated",
                "value": pt_value
            }
        }
        # Add pt-BR
        data["strings"][key]["localizations"]["pt-BR"] = {
            "stringUnit": {
                "state": "translated",
                "value": pt_value
            }
        }

with open("/Users/admin/Developer/Near/Near/Localizable.xcstrings", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Translations injected.")
