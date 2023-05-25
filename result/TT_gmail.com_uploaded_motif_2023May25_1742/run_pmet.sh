utils/PMETdev/scripts/pmetParallel_linux  -d /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/data/PMETindex/uploaded_motif/example_motif -g /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/result/wangxuesong29_gmail.com_uploaded_motif_2023May25_1742/genes_used_PMET.txt -i 24 -p promoter_lengths.txt -b binomial_thresholds.txt -c IC.txt -f fimohits -t 4 -o /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/result/wangxuesong29_gmail.com_uploaded_motif_2023May25_1742 > /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/result/wangxuesong29_gmail.com_uploaded_motif_2023May25_1742/PMETparallel.log

cat /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/result/wangxuesong29_gmail.com_uploaded_motif_2023May25_1742//temp*.txt > /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/result/wangxuesong29_gmail.com_uploaded_motif_2023May25_1742/PMET_OUTPUT.txt

rm /mnt/c/Users/wangx/Downloads/pmet_shiny_nginx/result/wangxuesong29_gmail.com_uploaded_motif_2023May25_1742//temp*.txt
