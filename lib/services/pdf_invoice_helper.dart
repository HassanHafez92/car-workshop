import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/workshop_models.dart';

class PdfInvoiceHelper {
  static Future<void> printInvoice({
    required Invoice invoice,
    required Customer customer,
    required Vehicle vehicle,
    required JobCard jobCard,
  }) async {
    final pdf = pw.Document();

    // Fetch Cairo font from Web for high fidelity Arabic shaping
    pw.Font? cairoFont;
    try {
      cairoFont = await PdfGoogleFonts.cairoRegular();
    } catch (e) {
      print("Failed to load Cairo font: $e");
    }

    // Secondary font in case we are offline (Helvetica will not shape Arabic but acts as safe fallback)
    final primaryFont = cairoFont ?? pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: primaryFont,
          bold: primaryFont,
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- Header Row ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Workshop Logo & Details
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'نظام إدارة ورش السيارات',
                            style: pw.TextStyle(
                              fontSize: 20,
                              color: PdfColor.fromHex('#00595C'), // Egyptian Teal
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('القاهرة، جمهورية مصر العربية', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('هاتف: 01012345678', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('الرقم الضريبي: 300123456700003', style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      // Invoice Label
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#00595C'),
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'فاتورة ضريبية مبسطة',
                              style: pw.TextStyle(
                                fontSize: 14,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text('رقم الفاتورة: ${invoice.invoiceNo}', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('التاريخ: ${invoice.createdAt}', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('طريقة الدفع: ${_translatePayment(invoice.paymentMethod)}', style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 2, color: PdfColor.fromHex('#00595C')),
                  pw.SizedBox(height: 10),

                  // --- Customer & Vehicle Info ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F4F7F6'),
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('بيانات العميل:', style: pw.TextStyle(color: PdfColor.fromHex('#00595C'), fontSize: 11)),
                              pw.SizedBox(height: 4),
                              pw.Text('الاسم: ${customer.name}', style: pw.TextStyle(fontSize: 10)),
                              pw.Text('الهاتف: ${customer.phone}', style: pw.TextStyle(fontSize: 10)),
                              pw.Text('العنوان: ${customer.address}', style: pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F4F7F6'),
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('بيانات المركبة:', style: pw.TextStyle(color: PdfColor.fromHex('#00595C'), fontSize: 11)),
                              pw.SizedBox(height: 4),
                              pw.Text('النوع/الموديل: ${vehicle.make} ${vehicle.model} (${vehicle.year})', style: pw.TextStyle(fontSize: 10)),
                              pw.Text('رقم اللوحة: ${vehicle.plateNumber}', style: pw.TextStyle(fontSize: 10)),
                              pw.Text('قراءة العداد: ${invoice.laborTotal > 0 ? jobCard.odometer : vehicle.odometer} كم', style: pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // --- Items Table ---
                  pw.Text('تفاصيل أجور الإصلاح وقطع الغيار:', style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#00595C'))),
                  pw.SizedBox(height: 8),

                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(4), // Item description
                      1: const pw.FlexColumnWidth(2), // Type
                      2: const pw.FlexColumnWidth(1.5), // Qty / Hrs
                      3: const pw.FlexColumnWidth(2), // Price
                      4: const pw.FlexColumnWidth(2), // Total
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#00595C'),
                        ),
                        children: [
                          _buildHeaderCell('البند / البيان'),
                          _buildHeaderCell('النوع'),
                          _buildHeaderCell('الكمية/الأيام'),
                          _buildHeaderCell('سعر الوحدة'),
                          _buildHeaderCell('الإجمالي'),
                        ],
                      ),
                      // Labor/Tasks Rows
                      ...jobCard.tasks.map((task) => pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                            ),
                            children: [
                              _buildCell(task.description),
                              _buildCell('أجور فنية'),
                              _buildCell('${task.estimatedHours} ساعة'),
                              _buildCell('${task.price.toStringAsFixed(2)} ج.م'),
                              _buildCell('${task.price.toStringAsFixed(2)} ج.م'),
                            ],
                          )),
                      // Parts Rows
                      ...jobCard.parts.map((part) => pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#FBFDFD'),
                            ),
                            children: [
                              _buildCell(part.name),
                              _buildCell('قطع غيار'),
                              _buildCell('${part.quantity}'),
                              _buildCell('${part.price.toStringAsFixed(2)} ج.م'),
                              _buildCell('${(part.price * part.quantity).toStringAsFixed(2)} ج.م'),
                            ],
                          )),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColor.fromHex('#E0E0E0')),
                  pw.SizedBox(height: 10),

                  // --- Financial Summary ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ملاحظات:', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('شكراً لاختياركم مركزنا لصيانة سيارتكم.', style: pw.TextStyle(fontSize: 9)),
                          pw.Text('القطع المستبدلة خاضعة للضمان لمدة 3 أشهر.', style: pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Container(
                        width: 220,
                        child: pw.Column(
                          children: [
                            _buildSummaryRow('إجمالي الأجور:', '${invoice.laborTotal.toStringAsFixed(2)} ج.م'),
                            _buildSummaryRow('إجمالي قطع الغيار:', '${invoice.partsTotal.toStringAsFixed(2)} ج.م'),
                            if (invoice.discount > 0)
                              _buildSummaryRow('الخصم الممنوح:', '- ${invoice.discount.toStringAsFixed(2)} ج.م', isDiscount: true),
                            _buildSummaryRow('ضريبة القيمة المضافة (15%):', '${invoice.tax.toStringAsFixed(2)} ج.م'),
                            pw.Divider(color: PdfColors.grey),
                            _buildSummaryRow(
                              'الصافي المستحق النهائي:',
                              '${invoice.netTotal.toStringAsFixed(2)} ج.م',
                              isBold: true,
                              color: PdfColor.fromHex('#00595C'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Show PDF layout
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'invoice_${invoice.invoiceNo}',
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  static pw.Widget _buildCell(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isDiscount = false, PdfColor? color}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: isDiscount ? PdfColors.red : PdfColors.black,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              color: color ?? (isDiscount ? PdfColors.red : PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static String _translatePayment(String method) {
    switch (method) {
      case 'cash':
        return 'نقدي (كاش)';
      case 'card':
        return 'شبكة / بطاقة مدى';
      case 'transfer':
        return 'حوالة بنكية';
      case 'credit':
        return 'على الحساب (آجل)';
      default:
        return method;
    }
  }
}
