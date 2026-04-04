// AddProjectSheet.swift
import SwiftUI

struct AddProjectSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let onSave: (String, String?, TaskScope) -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedScope: TaskScope = .work
    
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
                            
                            // Тип проекта
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Тип проекта")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Picker("Тип", selection: $selectedScope) {
                                    Text("Рабочий").tag(TaskScope.work)
                                    Text("Личный").tag(TaskScope.personal)
                                }
                                .pickerStyle(.segmented)
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
                    .padding(.bottom, 80) // Место для мышки
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
                        onSave(title, description.isEmpty ? nil : description, selectedScope)
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
