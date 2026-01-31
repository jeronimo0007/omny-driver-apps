#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para atualizar traduções:
- Mantém apenas: en, fr, es, pt, pt_BR
- Remove: hi, ar, tr, ru, it, de, ko, zh, iw, bn
- Adiciona traduções pt e pt_BR baseadas no inglês
"""

import re
import sys

def find_language_sections(content):
    """Encontra onde cada idioma começa e termina"""
    languages = {}
    pattern = r'^  "([a-z]{2}(_[A-Z]{2})?)": \{'
    
    lines = content.split('\n')
    for i, line in enumerate(lines):
        match = re.match(pattern, line)
        if match:
            lang_code = match.group(1)
            start = i
            
            # Encontra o fim deste bloco de idioma
            brace_count = 0
            end = start
            for j in range(start, len(lines)):
                line_content = lines[j]
                brace_count += line_content.count('{')
                brace_count -= line_content.count('}')
                if brace_count == 0 and j > start:
                    end = j
                    break
            
            languages[lang_code] = (start, end)
    
    return languages

def extract_language_section(content, start_line, end_line):
    """Extrai uma seção de idioma"""
    lines = content.split('\n')
    return '\n'.join(lines[start_line:end_line+1])

def create_pt_translation(en_content):
    """Cria tradução pt (Portugal) baseada no inglês - placeholder simples"""
    # Por enquanto, vamos usar o inglês como base e marcar para tradução
    # Em produção, você precisaria de traduções reais
    pt_content = en_content.replace('"en": {', '"pt": {')
    # Adicionar traduções reais aqui quando disponíveis
    return pt_content

def create_pt_br_translation(en_content):
    """Cria tradução pt_BR (Brasil) baseada no inglês - placeholder simples"""
    pt_br_content = en_content.replace('"en": {', '"pt_BR": {')
    # Adicionar traduções reais aqui quando disponíveis
    return pt_br_content

def main():
    file_path = 'lib/translation/translation.dart'
    
    print("Lendo arquivo...")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("Identificando seções de idiomas...")
    languages = find_language_sections(content)
    
    # Idiomas a manter
    keep_langs = ['en', 'fr', 'es']
    # Idiomas a adicionar
    add_langs = ['pt', 'pt_BR']
    
    print(f"Idiomas encontrados: {list(languages.keys())}")
    print(f"Idiomas a manter: {keep_langs}")
    print(f"Idiomas a adicionar: {add_langs}")
    
    # Extrair seções a manter
    kept_sections = {}
    for lang in keep_langs:
        if lang in languages:
            start, end = languages[lang]
            kept_sections[lang] = extract_language_section(content, start, end)
            print(f"✓ Mantido: {lang} (linhas {start+1}-{end+1})")
        else:
            print(f"✗ Não encontrado: {lang}")
    
    # Criar novas seções pt e pt_BR baseadas no inglês
    if 'en' in kept_sections:
        en_section = kept_sections['en']
        pt_section = create_pt_translation(en_section)
        pt_br_section = create_pt_br_translation(en_section)
        kept_sections['pt'] = pt_section
        kept_sections['pt_BR'] = pt_br_section
        print(f"✓ Criado: pt (baseado em en)")
        print(f"✓ Criado: pt_BR (baseado em en)")
    
    # Reconstruir o arquivo
    print("\nReconstruindo arquivo...")
    
    # Encontrar o início do Map
    lines = content.split('\n')
    header_end = 0
    for i, line in enumerate(lines):
        if line.strip().startswith('Map<String, dynamic> languages = {'):
            header_end = i
            break
    
    # Construir novo conteúdo
    new_lines = lines[:header_end+1]
    
    # Adicionar idiomas na ordem: en, fr, es, pt, pt_BR
    lang_order = ['en', 'fr', 'es', 'pt', 'pt_BR']
    for i, lang in enumerate(lang_order):
        if lang in kept_sections:
            section_lines = kept_sections[lang].split('\n')
            new_lines.extend(section_lines)
            if i < len(lang_order) - 1:  # Não adicionar vírgula no último
                new_lines.append(',')
    
    # Adicionar fechamento
    new_lines.append('};')
    
    new_content = '\n'.join(new_lines)
    
    # Salvar backup
    backup_path = file_path + '.backup'
    print(f"\nCriando backup: {backup_path}")
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Salvar novo arquivo
    print(f"Salvando novo arquivo: {file_path}")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print("\n✓ Concluído!")
    print(f"  - Backup salvo em: {backup_path}")
    print(f"  - Idiomas mantidos: {', '.join(keep_langs)}")
    print(f"  - Idiomas adicionados: {', '.join(add_langs)}")
    print("\n⚠️  NOTA: As traduções pt e pt_BR são placeholders baseados no inglês.")
    print("   Você precisará adicionar as traduções reais manualmente.")

if __name__ == '__main__':
    main()
