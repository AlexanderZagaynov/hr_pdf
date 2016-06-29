# frozen_string_literal: true

desc 'Convert file to PDF test'
task :convert, %i(dirname) => %i(environment) do |task, args|
  logger = Rails.logger
  logger.tagged 'Rake Task', 'Convert file to PDF test' do

    unless dirname = args[:dirname] and File.directory? dirname
      logger.warn 'Please provide a valid dir name.'
      next
    end

    lo_exe = '/Applications/LibreOffice.app/Contents/MacOS/soffice'
    workdir = Rails.root / 'tmp'
    content_file = workdir / 'content.xml'

    Dir.glob File.join(dirname, '*.{doc,docx,odt,ods,pdf,txt,text}') do |filename|
      basename = File.basename filename, '.*'
      odt_file = workdir / "#{basename}.odt"

      begin

        `#{lo_exe} --headless --convert-to odt:writer8 --outdir #{workdir} #{filename}`
        `unzip #{odt_file} content.xml -d #{workdir}`

        has_changes = false

        subs = %w(a e i o u).freeze
        rsubs = Regexp.new "[#{subs.join ''}]"
        xsubs = subs.map { |text| %Q[contains(text(), "#{text}")] }.join(' or ')

        doc = Nokogiri::XML content_file.read
        doc.xpath("//*[#{xsubs}]").each do |node|
          node.content = node.text.gsub rsubs, 'x'
          has_changes ||= true
        end

        if has_changes
          content_file.open('w') { content_file.write doc.to_xml }
          `zip -mj #{odt_file} #{content_file}`
        end

        `#{lo_exe} --headless --convert-to pdf --outdir #{workdir} #{odt_file}`
        `mv #{workdir / basename}.pdf #{workdir / File.basename(filename)}.pdf`

      ensure
        FileUtils.rm odt_file     if File.exist? odt_file
        FileUtils.rm content_file if File.exist? content_file
      end
    end
  end
end
