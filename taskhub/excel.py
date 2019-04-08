import os
import xlsxwriter

from taskhub.settings import get_storage

def _calc_height(hcols):
    max_line = 1
    for hcol in hcols:
        line_cnt = hcol.count("\n") + 1
        if line_cnt > max_line:
            max_line = line_cnt
    return max_line

def _calc_width(hcol):
    return max([len(col) for col in hcol.split("\n")])


def export(header, data, filename):
    if not filename.endswith(".xlsx"):
        filename = filename + ".xlsx"

    filepath = os.path.join(get_storage(), filename)
    workbook = xlsxwriter.Workbook(filepath)
    worksheet = workbook.add_worksheet()

    if header is not None:
        hcols = [h.strip() for h in header.split(',')]

        worksheet.set_row(0, _calc_height(hcols) * 16)

        # write header to xlsx
        for index, hcol in enumerate(hcols):
            width = _calc_width(hcol)
            worksheet.write(0, index, hcol)
            worksheet.set_column(index, index, width)


    # write data to xlsx
    # first row is header so start from row 1
    for ridx, row in enumerate(data):
        for cidx, col in enumerate(row):
            worksheet.write(ridx + 1, cidx, col)

    workbook.close()

    return filepath

