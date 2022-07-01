class UpDownload < ApplicationRecord
	validates_presence_of :name, :url, :message => '不能为空'

	def filename
		if self.url.split('/').last.rindex('.').blank?
      filename = self.url.split('/').last
    else
      filename_before = self.url.split('/').last[0,self.url.split('/').last.rindex('.')]
      filename_after = self.url.split('.').last
      filename = filename_before + '.' + filename_after
    end
	end

	def self.upload(file)
    if !file.original_filename.empty?
      direct = "#{Rails.root}/public/download/"
       
      if !File.exist?(direct)
        Dir.mkdir(direct)          
      end

      if file.original_filename.rindex('.').blank?
        filename = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}_#{file.original_filename}"
      else
        filename_before = file.original_filename[0, file.original_filename.rindex('.')]
        filename_after = file.original_filename.split('.').last
        filename = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}_#{filename_before+'.'+filename_after}"
      end

      file_path = direct + filename
    end
  end

  def self.write(file, file_path)
    File.open(file_path, "wb") do |f|
      f.write(file.read)
    end
  end
end
