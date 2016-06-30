# frozen_string_literal: true

class ConversionController < ApplicationController
  LO_EXE = ENV.fetch('LO_EXE') { '/Applications/LibreOffice.app/Contents/MacOS/soffice' }
  WORK_DIR = Rails.root / 'tmp'
  XML_FILE = WORK_DIR / 'content.xml'

  %w(a e i o u).tap do |subs|
    RSUBS = Regexp.new "[#{subs.join ''}]"
    XSUBS = "//*[#{subs.map { |text| %Q[contains(text(), "#{text}")] }.join(' or ')}]"
  end
  REPLACEMENT = 'x'

  def create
    original = params[:file]
    redirect_to action: :new and return if original == ''

    filename = original.original_filename
    filename = "#{filename}#{File.extname filename}"
    filename = WORK_DIR / filename
    File.open(filename, 'wb') { |file| file.write original.read }

    barename = File.basename filename, '.*'
    odt_file = WORK_DIR / "#{barename}.odt"
    pdf_file = WORK_DIR / "#{barename}.pdf"

    `#{LO_EXE} --invisible --convert-to odt:writer8 --outdir #{WORK_DIR} '#{filename}'`

    if odt_file.read(5) == '<?xml'
      xml_file = odt_file
    else
      `unzip '#{odt_file}' content.xml -d #{WORK_DIR}`
      xml_file = XML_FILE
    end

    has_changes = false

    doc = Nokogiri::XML xml_file.read
    doc.xpath(XSUBS).each do |node|
      node.content = node.text.gsub RSUBS, REPLACEMENT
      has_changes ||= true
    end

    if has_changes
      xml_file.open('w') { xml_file.write doc.to_xml }
      `zip -mj '#{odt_file}' #{XML_FILE}` if xml_file == XML_FILE
    end

    `#{LO_EXE} --headless --convert-to pdf --outdir #{WORK_DIR} '#{odt_file}'`
    send_data pdf_file.read, filename: File.basename(pdf_file)

  ensure
    [XML_FILE, odt_file, pdf_file, filename].each do |file|
      FileUtils.rm file if File.exist? file
    end
  end
end
