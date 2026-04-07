// AddProjectSheet.swift
import SwiftUI

struct AddProjectSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let scope: TaskScope  // ← передаём из ContentView
    let onSave: (String, String?) -> Void  // ← убрали scope из замыкания
    
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            // Поле названия
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Название проекта")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Например: Дизайн-проект", text: $title)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                            }
                            
                            // ✅ Информация о типе проекта (просто показываем, не даём выбрать)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Тип проекта")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Image(systemName: scope == .work ? "briefcase" : "person")
                                        .foregroundColor(Color.customBlueLight)
                                    Text(scope == .work ? "Рабочий" : "Личный")
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.customBlueLight.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Поле описания
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Описание (необязательно)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Расскажите о проекте...", text: $description, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }
                        .padding(24)
                        .background(Color.adaptiveCard)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
                
                // Мышь
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Mouse_ProjectIn")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 350)
                            .padding(.trailing, -10)
                            .padding(.bottom, -80)
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
            .navigationTitle("Новый проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.adaptiveBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(Color.customBlueLight)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        onSave(title, description.isEmpty ? nil : description)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : Color.customBlueLight)
                }
            }
        }
    }
}
