///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОбработчикиСобытий
Процедура ПередЗаписью(Отказ, Замещение)
	
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	
	Если Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ТекущийНаборЗаписей.Объект КАК Объект,
		|	1 КАК КоличествоПопыток,
		|	&ВремяТекущейПопытки КАК ВремяПоследнейПопытки
		|ПОМЕСТИТЬ ТекущийНабор
		|ИЗ
		|	&ТекущийНаборЗаписей КАК ТекущийНаборЗаписей
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	Таблица.Объект КАК Объект,
		|	Результат(Таблица.КоличествоПопыток) КАК КоличествоПопыток,
		|	МАКСИМУМ(Таблица.ВремяПоследнейПопытки) КАК ВремяПоследнейПопытки
		|ИЗ
		|	(ВЫБРАТЬ
		|		НеудаленныеОбъекты.Объект КАК Объект,
		|		НеудаленныеОбъекты.КоличествоПопыток КАК КоличествоПопыток,
		|		НеудаленныеОбъекты.ВремяПоследнейПопытки КАК ВремяПоследнейПопытки
		|	ИЗ
		|		РегистрСведений.НеудаленныеОбъекты КАК НеудаленныеОбъекты
		|	ГДЕ
		|		НеудаленныеОбъекты.Объект В
		|			(ВЫБРАТЬ
		|				Таб.Объект
		|			ИЗ
		|				ТекущийНабор КАК Таб)
		|
		|	ОБЪЕДИНИТЬ ВСЕ
		|
		|	ВЫБРАТЬ
		|		ТекущийНабор.Объект,
		|		ТекущийНабор.КоличествоПопыток,
		|		ТекущийНабор.ВремяПоследнейПопытки
		|	ИЗ
		|		ТекущийНабор КАК ТекущийНабор) КАК Таблица
		|СГРУППИРОВАТЬ ПО
		|	Таблица.Объект";
	
	Запрос.УстановитьПараметр("ВремяТекущейПопытки", ОбщегоНазначения.ТекущаяДатаПользователя());
	Запрос.УстановитьПараметр("ТекущийНаборЗаписей", Выгрузить());
	
	РезультатЗапроса = Запрос.Выполнить();
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Очистить();
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		ЗаполнитьЗначенияСвойств(Добавить(), ВыборкаДетальныеЗаписи);
	КонецЦикла;
	
КонецПроцедуры
#КонецОбласти

#Иначе
ВызватьИсключение НСтр("ru = 'Недопустимый вызов объекта на клиенте.'");
#КонецЕсли